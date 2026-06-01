.pragma library
.import "CompositeSearchText.js" as Text
.import "CompositeSearchEvidence.js" as Evidence
.import "CompositeSearchEvaluate.js" as Evaluate


var clamp = Text.clamp;
var matchField = Evidence.matchField;
var scoreEvidence = Evidence.scoreEvidence;
var evidenceFieldGroup = Evidence.evidenceFieldGroup;
var overlayEvidence = Evidence.overlayEvidence;
var compareEvaluated = Evaluate.compareEvaluated;
var collectParentChain = Evaluate.collectParentChain;

function groupDisplayPolicy(ev) {
    var flattenPolicy = ev.node.behavior && ev.node.behavior.flattenPolicy || {};
    var groupPolicy = flattenPolicy.groupDisplay || {};
    if (flattenPolicy.modeHint !== "group-dominance" && !groupPolicy.enabled)
        return null;
    return Object.assign({ enabled: true, parentWinsMargin: 0.08, childWinsMargin: 0.03, childDominatesMargin: 0.18, maxFlattenedChildren: 3, minChildScore: 0.25, showGroupHeaderInFilteredMode: true, committedTokenPrefersGroup: true, committedTokenMinParentScore: 0.25, showAllChildrenOnParentMatch: false, parentMatchMinScore: 0.25 }, groupPolicy);
}

function groupDominanceOwnScore(ev, ctx) {
    var primary = (ev.evidence || []).filter(function(e) {
        if (e.nodeId !== ev.node.id) return false;
        var group = evidenceFieldGroup(e.field);
        return group === "primary-text" || group === "path-text" || group === "semantic-text";
    });
    if (!primary.length)
        return ev.ownScore;
    var score = 0;
    var overlaid = overlayEvidence(primary, ctx.query);
    for (var i = 0; i < overlaid.length; i += 1)
        score = 1 - (1 - score) * (1 - clamp(overlaid[i].effective));
    return clamp(Math.min(score, ev.ownScore));
}

function decideGroupDisplay(ev, ctx) {
    if (ev.node.switchActions)
        return { mode: "group", showParent: true, children: [] };

    var policy = groupDisplayPolicy(ev);
    if (!policy)
        return { mode: "normal", showParent: true, children: ev.children };
    var parentScore = groupDominanceOwnScore(ev, ctx);
    if (policy.showAllChildrenOnParentMatch && parentScore >= policy.parentMatchMinScore)
        return { mode: "nested-group", showParent: true, children: ev.children.slice(0, policy.maxNestedChildren || ev.children.length) };
    var visibleChildren = ev.children.filter(function(c) { return c.visible && c.score >= policy.minChildScore; }).sort(compareEvaluated);
    if (!visibleChildren.length)
        return { mode: "group", showParent: true, children: [] };
    var bestChild = visibleChildren[0];
    if (policy.committedTokenPrefersGroup && ctx.query.lastTokenEmpty && parentScore >= policy.committedTokenMinParentScore)
        return { mode: "filtered-group", showParent: true, children: visibleChildren.slice(0, policy.maxFlattenedChildren) };
    if (parentScore >= bestChild.score + policy.parentWinsMargin)
        return { mode: "group", showParent: true, children: [] };
    if (bestChild.score >= parentScore + policy.childDominatesMargin)
        return { mode: "flatten-children", showParent: false, children: visibleChildren.slice(0, policy.maxFlattenedChildren) };
    return { mode: "filtered-group", showParent: policy.showGroupHeaderInFilteredMode, children: visibleChildren.slice(0, policy.maxFlattenedChildren) };
}

function rangesForField(evidenceItems, fieldName, nodeId) {
    var ranges = [];
    for (var i = 0; i < (evidenceItems || []).length; i += 1) {
        var e = evidenceItems[i];
        if (e.field === fieldName && (!nodeId || e.nodeId === nodeId))
            ranges = ranges.concat(e.ranges || []);
    }
    return ranges;
}

function defaultActionForNode(node, query, ownScore) {
    var actions = node.actionList || [];
    if (!node.switchActions)
        return actions[0] || null;
    var tokens = (query.tokens || []).map(function(t) { return t.normalized; });
    var best = { id: "", score: 0 };
    var aliases = {
        on: ["on", "enable", "connect"],
        off: ["off", "disable", "disconnect"],
        toggle: ["toggle", "switch"]
    };
    var switchAcronym = String(node.label || "").replace(/[^A-Za-z0-9]/g, "").charAt(0).toLowerCase();
    if (switchAcronym) {
        aliases.on.push(switchAcronym + "o");
        aliases.off.push(switchAcronym + "f");
        aliases.toggle.push(switchAcronym + "t");
    }
    for (var id in aliases) {
        for (var ti = 0; ti < tokens.length; ti += 1) {
            for (var ai = 0; ai < aliases[id].length; ai += 1) {
                var alias = aliases[id][ai];
                var token = tokens[ti];
                var score = token === alias ? 1 : alias.indexOf(token) === 0 && token.length >= 2 ? 0.78 + token.length / Math.max(20, alias.length * 20) : alias.length > token.length && alias.lastIndexOf(token) === alias.length - token.length ? (token.length >= 2 ? 0.72 + token.length / Math.max(20, alias.length * 20) : 0.75) : 0;
                if (score > best.score)
                    best = { id: id, score: score };
            }
        }
    }
    if (best.id && node.switchActions[best.id])
        return node.switchActions[best.id];
    return node.switchActions.toggle || actions[0] || null;
}

function toResultRow(ev, depth, state, ctx, childRows) {
    var node = ev.node;
    var chain = collectParentChain(node);
    var breadcrumbs = chain.slice(0, -1).map(function(n) { return n.label; });
    var action = defaultActionForNode(node, ctx.query, ev.ownScore);
    if (childRows && childRows.length) {
        var bestChildRow = childRows.slice().sort(function(a, b) { return b.score - a.score; })[0];
        if (bestChildRow && bestChildRow.executable && bestChildRow.enter && bestChildRow.enter.action && (bestChildRow.score > ev.ownScore + 0.03 || (ctx.query.tokens.length > 1 && bestChildRow.score >= 0.9 && bestChildRow.score > ev.ownScore - 0.08)))
            action = bestChildRow.enter.action;
    }
    var actions = (node.actionList || []).slice();
    if (node.switchActions) {
        actions = [node.switchActions.toggle, node.switchActions.on, node.switchActions.off].filter(Boolean);
        for (var ai = 0; ai < actions.length; ai += 1)
            actions[ai].default = action && actions[ai].id === action.id;
    }
    return {
        id: "row:" + node.id,
        nodeId: node.id,
        source: node.backendId,
        backendId: node.backendId,
        kind: node.kind,
        title: node.label,
        label: node.label,
        subtitle: node.subtitle,
        icon: node.icon,
        depth: depth,
        score: ev.score,
        ownScore: ev.ownScore,
        evidence: ev.evidence,
        selected: state.selectedNodeId === node.id,
        expandable: ev.children.length > 0,
        expanded: state.expandedNodeIds[node.id] || node.kind === "backend",
        breadcrumbs: breadcrumbs,
        labelMatches: rangesForField(ev.evidence, "label", node.id),
        subtitleMatches: rangesForField(ev.evidence, "subtitle", node.id),
        actions: actions,
        enter: action ? { type: "activate", action: action } : { type: "noop" },
        shiftEnter: { type: "noop" },
        executable: !!action,
        dangerous: !!node.dangerous,
        children: childRows || [],
        switchActions: node.switchActions || null,
        switchState: node.switchState === undefined ? null : node.switchState,
        metadata: Object.assign({}, node.meta || {}, { nodeId: node.id, action: action })
    };
}

function flattenForUi(evaluatedRoot, state, ctx) {
    var collected = [];
    function canInclude(ev) {
        if (ctx.directive && ctx.directive.active && !ev.allowed) return false;
        if (!(ev.visible || ctx.showHidden)) return false;
        if (ev.node.kind === "backend") return false;
        return true;
    }
    function add(ev, depth, sortScore, childEvs) {
        if (ev.node.kind !== "root" && canInclude(ev))
            collected.push({ ev: ev, depth: depth, sortScore: sortScore === undefined ? ev.score : sortScore, childEvs: childEvs || [] });
    }
    function collect(ev, depth) {
        if (ev.node.kind === "root") {
            for (var i = 0; i < ev.children.length; i += 1) collect(ev.children[i], depth + 1);
            return;
        }
        if (ev.node.kind === "backend") {
            for (var bi = 0; bi < ev.children.length; bi += 1) collect(ev.children[bi], depth);
            return;
        }
        var decision = decideGroupDisplay(ev, ctx);
        if (decision.mode === "normal") {
            add(ev, depth);
            for (var n = 0; n < ev.children.length; n += 1) collect(ev.children[n], depth + 1);
            return;
        }
        if (decision.showParent) {
            var childMaxScore = decision.children.length ? Math.max.apply(null, decision.children.map(function(c) { return c.score; })) : 0;
            var score = decision.mode === "filtered-group" || decision.mode === "nested-group" ? Math.max(ev.score, childMaxScore) + 0.04 : ev.score;
            if (decision.mode === "nested-group") {
                add(ev, depth, score, decision.children);
                return;
            }
            add(ev, depth, score, decision.mode === "filtered-group" ? decision.children : []);
            if (decision.mode === "filtered-group") {
                for (var ci = 0; ci < decision.children.length; ci += 1)
                    add(decision.children[ci], depth + 1, score - (ci + 1) * 0.0001);
                return;
            }
        }
        if (decision.mode === "group")
            return;
        for (var di = 0; di < decision.children.length; di += 1)
            collect(decision.children[di], decision.mode === "flatten-children" ? depth : depth + 1);
    }
    collect(evaluatedRoot, -1);
    collected.sort(function(a, b) {
        var delta = b.sortScore - a.sortScore;
        if (Math.abs(delta) > 0.0001) return delta;
        var priorityDelta = (b.ev.node.behavior && b.ev.node.behavior.flattenPolicy && b.ev.node.behavior.flattenPolicy.priority || 0) - (a.ev.node.behavior && a.ev.node.behavior.flattenPolicy && a.ev.node.behavior.flattenPolicy.priority || 0);
        if (priorityDelta !== 0) return priorityDelta;
        return a.depth - b.depth;
    });
    return collected.map(function(item) {
        var childRows = (item.childEvs || []).filter(function(child) { return child.allowed && child.node.kind !== "backend"; }).map(function(child) { return toResultRow(child, item.depth + 1, state, ctx, []); });
        return toResultRow(item.ev, item.depth, state, ctx, childRows);
    });
}
