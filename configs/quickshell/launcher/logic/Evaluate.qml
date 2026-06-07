pragma Singleton
import QtQml
import Quickshell
import "Tokenize.qml"
import "IndexBuilder.qml"
import "Evidence.qml"
import "CompositeSearchPolicyRegistry.js" as JsRegistry

Singleton {
    readonly property var defaultProfile: ({
        evidence: ["field-match:all", "switch-action", "semantic", "token-claim", "usage", "recency"],
        inherit: ["path-evidence"],
        boost: ["descendant-boost"],
        childVisible: ["visible-flag"],
        childBypass: ["own-score-beats-parent", "score-dominates:0.03"]
    })

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
        var closure = IndexBuilder.computeDirectiveTagClosure(node);
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
            return { node: node, allowed: false, candidate: false, pruned: true, evidence: [], ownEvidence: [], inheritedEvidence: [], ownScore: 0, inheritedScore: 0, score: 0, visible: false, children: [] };

        var directiveBrowse = directiveActive && query.isEmpty;
        if (ctx.candidateIds && !ctx.candidateIds[node.id] && node.kind !== "root" && node.kind !== "backend" && !node.showWhenQueryEmpty && !(query.isEmpty && node.backendId === "backends" && directiveActive) && !directiveBrowse && !ctx.showHidden)
            return { node: node, allowed: selfAllowed, candidate: false, pruned: true, evidence: [], ownEvidence: [], inheritedEvidence: [], ownScore: 0, inheritedScore: 0, score: 0, visible: false, children: [] };

        var ep = node.evaluationProfile || {};
        var profile = ep.profile || defaultProfile;

        var ownEvidence = [];
        var inheritedEvidence = [];
        var directCandidate = !ctx.candidateIds || !!ctx.candidateIds[node.id] || node.kind === "root" || node.kind === "backend" || node.showWhenQueryEmpty || directiveBrowse;

        if (selfAllowed && directCandidate) {
            var evidencePolicies = profile.evidence || [];
            for (var pi = 0; pi < evidencePolicies.length; pi += 1) {
                var policy = JsRegistry.evidence.get(evidencePolicies[pi]);
                if (!policy || policy.phase !== "evidence")
                    continue;
                var items = policy.match(node, query, ctx);
                if (!items || !items.length)
                    continue;
                if (policy.group === "inherited")
                    inheritedEvidence = inheritedEvidence.concat(items);
                else
                    ownEvidence = ownEvidence.concat(items);
            }
        }

        var evaluatedChildren = evaluateChildren(node, query, ctx, directiveActive);

        var own = selfAllowed ? Evidence.scoreEvidence(ownEvidence, node, ctx) : { value: 0, visible: false, reason: "directive container only" };
        if (node.kind === "backend") {
            own.value = Tokenize.clamp(own.value * 0.65);
            own.visible = ctx.query.isEmpty || own.visible;
        }
        if (ep.scorePolicy === "semantic-result")
            own.visible = ownEvidence.length > 0;

        var inheritedResult = selfAllowed && inheritedEvidence.length ? Evidence.scoreEvidence(inheritedEvidence, node, ctx) : { value: 0 };
        var inheritedScore = inheritedResult.value;

        var scores = { ownScore: own.value, inheritedScore: inheritedScore };
        var descendantBoost = 0;
        var boostPolicies = profile.boost || [];
        for (var bi = 0; bi < boostPolicies.length; bi += 1) {
            var bpol = JsRegistry.boost.get(boostPolicies[bi]);
            if (!bpol || bpol.phase !== "boost")
                continue;
            var boostVal = bpol.apply(node, query, ctx, evaluatedChildren, scores);
            if (boostVal > 0)
                descendantBoost = Math.max(descendantBoost, boostVal);
        }

        var finalScore = Tokenize.clamp(Math.max(own.value, inheritedScore, descendantBoost));

        var actionAliasBoost = 0;
        if (node.switchActions && own.value > 0) {
            var aliasPol = JsRegistry.boost.get("switch-aliases");
            if (aliasPol) {
                var aliasBoostVal = aliasPol.apply(node, query, ctx, evaluatedChildren, scores);
                if (aliasBoostVal > 0)
                    actionAliasBoost = aliasBoostVal;
            }
        }
        if (actionAliasBoost > 0)
            finalScore = Tokenize.clamp(finalScore + own.value * 0.15 * actionAliasBoost);

        var groupDisplay = node.behavior && node.behavior.flattenPolicy && node.behavior.flattenPolicy.groupDisplay || {};
        var keepAllChildren = (groupDisplay.showAllChildrenOnParentMatch || groupDisplay.flattenAllChildrenOnParentMatch) && own.visible;
        var retained = evaluatedChildren.filter(function(c) { return keepAllChildren || c.candidate || c.visible || ctx.showHidden; });
        var bestChildMatchDepth = 9999;
        for (var b = 0; b < retained.length; b += 1) {
            if (retained[b].visible || ctx.showHidden) {
                var d = (retained[b].matchDepth === undefined ? 0 : retained[b].matchDepth) + 1;
                if (d < bestChildMatchDepth)
                    bestChildMatchDepth = d;
            }
        }

        var mergedEvidence = ownEvidence.concat(inheritedEvidence);

        return {
            node: node,
            allowed: selfAllowed,
            candidate: (selfAllowed && (directCandidate || ownEvidence.length > 0 || own.visible)) || retained.length > 0,
            pruned: false,
            evidence: mergedEvidence,
            ownEvidence: ownEvidence,
            inheritedEvidence: inheritedEvidence,
            ownScore: own.value,
            inheritedScore: inheritedScore,
            descendantScore: descendantBoost,
            score: finalScore,
            matchDepth: own.visible ? 0 : bestChildMatchDepth < 9999 ? bestChildMatchDepth : 9999,
            ownVisible: own.visible,
            visible: ctx.showHidden || own.visible || retained.some(function(c) { return c.visible || ctx.showHidden; }) || (ctx.query.isEmpty && node.kind === "backend" && !directiveActive),
            visibleReason: own.reason,
            children: keepAllChildren ? retained : retained.sort(compareEvaluated)
        };
    }

    function evaluateChildren(node, query, ctx, directiveActive) {
        var children = node.children || [];

        var routeCtx = ctx && ctx.route;
        if (routeCtx && routeCtx.combine === "exclusive" && routeCtx.endpoints && routeCtx.endpoints.length > 0) {
            var allowedIds = {};
            for (var ri = 0; ri < routeCtx.endpoints.length; ri += 1) {
                var ep = routeCtx.endpoints[ri];
                if (ep.node && ep.node.backendId)
                    allowedIds[ep.node.backendId] = true;
            }
            var exclusiveChildren = children.filter(function(child) {
                return child.backendId && allowedIds[child.backendId];
            });
            if (exclusiveChildren.length > 0)
                return evaluateChildList(exclusiveChildren, query, ctx, directiveActive);
        }
        return evaluateChildList(children, query, ctx, directiveActive);
    }

    function evaluateChildList(children, query, ctx, directiveActive) {
        var out = [];
        for (var i = 0; i < (children || []).length; i += 1) {
            var child = children[i];
            if (!directiveActive || nodeTreeMayContainDirective(child, ctx))
                out.push(evaluateNode(child, query, ctx));
        }
        return out;
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

    function fuzzyAliasScore(token, alias) {
        var maxDistance = Tokenize.fuzzyDistanceLimit(token, alias);
        if (maxDistance <= 0 || Math.abs(alias.length - token.length) > maxDistance || token === alias)
            return 0;
        var distance = Tokenize.boundedDamerauLevenshtein(token, alias, maxDistance);
        if (distance > maxDistance)
            return 0;
        var similarity = 1 - distance / Math.max(token.length, alias.length, 1);
        return 0.44 + similarity * 0.14;
    }

    function applyInheritPolicies(evaluated, query, ctx) {
        for (var i = 0; i < evaluated.children.length; i += 1)
            applyInheritPolicies(evaluated.children[i], query, ctx);

        var ep = evaluated.node.evaluationProfile || {};
        var profile = ep.profile || defaultProfile;
        var inheritNames = profile.inherit || [];
        for (var pi = 0; pi < inheritNames.length; pi += 1) {
            var policy = JsRegistry.inherit.get(inheritNames[pi]);
            if (policy && policy.phase === "inherit")
                policy.apply(evaluated, query, ctx);
        }
    }

    function hasBaseEvidence(ev) {
        return (ev.ownEvidence || ev.evidence || []).some(function(e) {
            return e.field !== "usage" && e.field !== "recency";
        });
    }
}
