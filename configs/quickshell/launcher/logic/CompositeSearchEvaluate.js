.pragma library
.import "CompositeSearchText.js" as Text
.import "CompositeSearchIndex.js" as Index
.import "CompositeSearchEvidence.js" as Evidence


var clamp = Text.clamp;
var searchableFields = Index.searchableFields;
var computeDirectiveTagClosure = Index.computeDirectiveTagClosure;
var matchField = Evidence.matchField;
var matchSemantic = Evidence.matchSemantic;
var claimMatchingTokens = Evidence.claimMatchingTokens;
var tokenClaimToEvidence = Evidence.tokenClaimToEvidence;
var scoreEvidence = Evidence.scoreEvidence;
var recencyScore = Evidence.recencyScore;
var frequencyScore = Evidence.frequencyScore;

function nodeMatchesDirective(node, ctx) {
    var directive = ctx.directive;
    if (!directive || !directive.active)
        return true;
    if (node.kind === "root")
        return true;
    if (directive.backendIds && directive.backendIds.indexOf(node.backendId) >= 0)
        return true;
    for (var i = 0; i < (directive.tags || []).length; i += 1) {
        if ((node.tags || []).indexOf(directive.tags[i]) >= 0)
            return true;
    }
    return false;
}

function nodeTreeMayContainDirective(node, ctx) {
    if (nodeMatchesDirective(node, ctx))
        return true;
    var closure = computeDirectiveTagClosure(node);
    for (var i = 0; i < (ctx.directive.tags || []).length; i += 1) {
        if (closure[ctx.directive.tags[i]])
            return true;
    }
    return false;
}

function evaluateNode(node, query, ctx) {
    var directiveActive = !!(ctx.directive && ctx.directive.active);
    var selfAllowed = !directiveActive || nodeMatchesDirective(node, ctx);
    if (directiveActive && !selfAllowed && !nodeTreeMayContainDirective(node, ctx))
        return { node: node, allowed: false, candidate: false, pruned: true, evidence: [], ownScore: 0, score: 0, visible: false, children: [] };

    if (ctx.candidateIds && !ctx.candidateIds[node.id] && node.kind !== "root" && node.kind !== "backend" && !node.showWhenQueryEmpty && !(query.isEmpty && node.backendId === "backends" && directiveActive) && !ctx.showHidden)
        return { node: node, allowed: selfAllowed, candidate: false, pruned: true, evidence: [], ownScore: 0, score: 0, visible: false, children: [] };

    var profile = node.evaluationProfile || {};
    var strategyIds = profile.strategies || ["exact", "prefix", "compact", "substring", "acronym", "semantic", "usage", "recency"];
    var evidenceItems = [];

    var directCandidate = !ctx.candidateIds || !!ctx.candidateIds[node.id] || node.kind === "root" || node.kind === "backend" || node.showWhenQueryEmpty;

    if (selfAllowed && directCandidate) {
        if (node.behavior && node.behavior.tokenPolicy && node.behavior.tokenPolicy.tokens) {
            var claims = claimMatchingTokens(query, node.behavior.tokenPolicy.tokens, node.behavior.tokenPolicy);
            for (var ci = 0; ci < claims.length; ci += 1)
                evidenceItems.push(tokenClaimToEvidence(node, query, claims[ci]));
        }
        var fields = searchableFields(node);
        for (var fi = 0; fi < fields.length; fi += 1)
            evidenceItems = evidenceItems.concat(matchField(fields[fi], query, strategyIds));
        if (strategyIds.indexOf("semantic") >= 0 || strategyIds.indexOf("desktop-action") >= 0)
            evidenceItems = evidenceItems.concat(matchSemantic(node, query));
        var hasBase = evidenceItems.some(function(e) { return e.field !== "usage" && e.field !== "recency"; });
        if (hasBase && strategyIds.indexOf("usage") >= 0 && node.usageCount > 0) {
            var usage = frequencyScore(node.usageCount);
            evidenceItems.push({ strategy: "usage", field: "usage", fieldText: String(node.usageCount), nodeId: node.id, kind: "frequency", score: usage, weight: 0.12, effective: usage * 0.12, ranges: [], reason: "usage frequency" });
        }
        if (hasBase && strategyIds.indexOf("recency") >= 0 && isFinite(node.lastUsedDaysAgo)) {
            var rec = recencyScore(node.lastUsedDaysAgo);
            evidenceItems.push({ strategy: "recency", field: "recency", fieldText: String(node.lastUsedDaysAgo), nodeId: node.id, kind: "recency", score: rec, weight: 0.08, effective: rec * 0.08, ranges: [], reason: "last used" });
        }
    }

    var evaluatedChildren = [];
    for (var i = 0; i < (node.children || []).length; i += 1) {
        var child = node.children[i];
        if (!directiveActive || nodeTreeMayContainDirective(child, ctx))
            evaluatedChildren.push(evaluateNode(child, query, ctx));
    }
    var own = selfAllowed ? scoreEvidence(evidenceItems, node, ctx) : { value: 0, visible: false, reason: "directive container only" };
    if (node.kind === "backend") {
        own.value = clamp(own.value * 0.65);
        own.visible = ctx.query.isEmpty || own.visible;
    }
    if (profile.scorePolicy === "semantic-result")
        own.visible = evidenceItems.length > 0;

    var groupDisplay = node.behavior && node.behavior.flattenPolicy && node.behavior.flattenPolicy.groupDisplay || {};
    var keepAllChildren = groupDisplay.showAllChildrenOnParentMatch && own.visible;
    var retained = evaluatedChildren.filter(function(c) { return keepAllChildren || c.candidate || c.visible || ctx.showHidden; });
    var bestChildScore = 0;
    for (var b = 0; b < retained.length; b += 1) {
        if (retained[b].visible || ctx.showHidden)
            bestChildScore = Math.max(bestChildScore, retained[b].score);
    }
    var descendantBoost = bestChildScore > 0 ? bestChildScore * (node.switchActions ? own.value > 0 ? 1 : 0.82 : node.kind === "backend" ? 0.82 : 0.28) : 0;
    var finalScore = clamp(Math.max(own.value, descendantBoost));
    return {
        node: node,
        allowed: selfAllowed,
        candidate: (selfAllowed && (directCandidate || evidenceItems.length > 0 || own.visible)) || retained.length > 0,
        pruned: false,
        evidence: evidenceItems,
        ownScore: own.value,
        score: finalScore,
        visible: ctx.showHidden || own.visible || retained.some(function(c) { return c.visible || ctx.showHidden; }) || (ctx.query.isEmpty && node.kind === "backend" && !directiveActive),
        visibleReason: own.reason,
        children: keepAllChildren ? retained : retained.sort(compareEvaluated)
    };
}

function compareEvaluated(a, b) {
    var scoreDelta = b.score - a.score;
    if (Math.abs(scoreDelta) > 0.0001) return scoreDelta;
    var backendDelta = (b.node.backendPriority || 0) - (a.node.backendPriority || 0);
    if (backendDelta !== 0) return backendDelta;
    var lengthDelta = String(a.node.label || "").length - String(b.node.label || "").length;
    if (lengthDelta !== 0) return lengthDelta;
    return String(a.node.label || "").localeCompare(String(b.node.label || ""));
}

function collectParentChain(node) {
    var chain = [];
    var cur = node;
    while (cur && cur.kind !== "root") {
        chain.unshift(cur);
        cur = cur.parent;
    }
    return chain;
}

function pathEvidenceFromAncestors(node, query, ctx) {
    if (!ctx.includePath || query.isEmpty)
        return [];
    var chain = collectParentChain(node).slice(0, -1);
    var out = [];
    var weight = 0.24;
    for (var i = 0; i < chain.length; i += 1) {
        var fields = searchableFields(chain[i]).filter(function(f) { return ["label", "aliases", "keywords"].indexOf(f.field) >= 0; });
        for (var fi = 0; fi < fields.length; fi += 1) {
            var inherited = Object.assign({}, fields[fi], { field: "ancestor-" + fields[fi].field, weight: weight * Math.min(1, fields[fi].weight) });
            out = out.concat(matchField(inherited, query, ["exact", "prefix", "compact", "substring", "acronym"]));
        }
        weight *= 0.72;
    }
    return out;
}

function injectPathEvidence(ev, query, ctx) {
    for (var i = 0; i < ev.children.length; i += 1)
        injectPathEvidence(ev.children[i], query, ctx);
    if (ev.node.kind === "root" || ev.node.kind === "backend")
        return;
    var inherited = pathEvidenceFromAncestors(ev.node, query, ctx);
    if (!inherited.length)
        return;
    ev.evidence = ev.evidence.concat(inherited.map(function(e) { return Object.assign({}, e, { kind: "path-" + e.kind, weight: e.weight * 0.7, effective: e.score * e.weight * 0.7 }); }));
    var own = scoreEvidence(ev.evidence, ev.node, ctx);
    ev.ownScore = own.value;
    ev.score = clamp(Math.max(ev.score, own.value));
    ev.visible = ev.visible || own.visible;
}
