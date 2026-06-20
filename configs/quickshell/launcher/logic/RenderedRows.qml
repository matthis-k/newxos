pragma Singleton
import QtQml
import Quickshell
import "Tokenize.qml"
import "Evidence.qml"
import "Evaluate.qml"
import "ScoreBundle.qml"
import "PresentationContext.qml"
import "../policies/presentation/"

Singleton {
    function toResultRow(ev, depth, state, ctx, childRows, options, shapedItem, parentPresentationContext) {
        options = options || {};
        var node = ev.node;
        var chain = Evaluate.collectParentChain(node);

        var presCtx = shapedItem
            ? PresentationContext.forShapedItem(ev, shapedItem, parentPresentationContext)
            : PresentationContext.emptyContext();

        var breadcrumbs = presCtx.breadcrumbs.length > 0
            ? presCtx.breadcrumbs
            : chain.slice(0, -1).map(function(n) { return n.label; });
        var brRoot = chain.find(function(n) { return n.behavior && n.behavior.visualRoot; });
        if (presCtx.breadcrumbs.length === 0 && brRoot)
            breadcrumbs = breadcrumbs.slice(chain.indexOf(brRoot));

        var displayPolicy = displayPolicyFor(node);
        var breadcrumbText = presCtx.showBreadcrumbs
            ? presCtx.breadcrumbText
            : breadcrumbTextFor(ev, breadcrumbs, displayPolicy, childRows);
        var selectedAction = ActionPolicy.selectDefaultAction(node, ctx.query, ev, ctx);
        var action = selectedAction ? selectedAction.action : null;
        var suppressOwnActions = action && childRows && childRows.length && ctx.query.tokens.length > 1
            && (options.suppressParentActions || visibleFromChildrenOnly(ev));
        if (suppressOwnActions) {
            action = null;
            selectedAction = null;
        }

        var sourceActions = suppressOwnActions ? [] : (node.actionList || []).slice();
        if (node.switchActions) {
            sourceActions = [node.switchActions.toggle, node.switchActions.on, node.switchActions.off].filter(Boolean);
        }
        var actions = copyActionList(sourceActions, action);
        var enterAction = action ? copyAction(action, true) : null;

        var placement = shapedItem ? shapedItem.placement : presCtx.placement;

        var hasReplaceQuery = !!(node.meta && node.meta.replaceQuery);

        var semantics = shapedItem && shapedItem.semantics ? shapedItem.semantics : null;

        var row = {
            id: "row:" + node.id,
            nodeId: node.id,
            source: node.backendId,
            backendId: node.backendId,
            kind: node.kind,
            title: node.label,
            label: node.label,
            subtitle: node.subtitle,
            icon: node.icon,
            iconColor: node.iconColor || null,
            depth: depth,
            placement: placement,
            score: ev.score,
            ownScore: ev.ownScore,
            inheritedScore: ev.inheritedScore || 0,
            descendantScore: ev.descendantScore || 0,
            ownVisible: !!ev.ownVisible,
            matchDepth: ev.matchDepth === undefined ? depth : ev.matchDepth,
            evidence: copyEvidence(ev.evidence || []),
            selected: state.selectedNodeId === node.id,
            expandable: childRows ? childRows.length > 0 : (ev.children && ev.children.length > 0),
            expanded: state.expandedNodeIds[node.id] || node.kind === "backend",
            breadcrumbs: breadcrumbs,
            breadcrumbText: breadcrumbText,
            display: Object.assign({ breadcrumbText: breadcrumbText, showBreadcrumbs: presCtx.showBreadcrumbs, showBackendBadge: presCtx.showBackendBadge, showActionHint: presCtx.showActionHint, density: presCtx.density }, displayPolicy),
            labelMatches: copyRanges(rangesForField(ev.evidence, "label", node.id)),
            subtitleMatches: copyRanges(rangesForField(ev.evidence, "subtitle", node.id)),
            semantics: semantics,
            actions: actions,
            enter: enterAction
                ? (enterAction.payload && enterAction.payload.replaceQuery
                    ? { type: "sequence", steps: [{ type: "activate", action: enterAction }] }
                    : { type: "sequence", steps: [{ type: "activate", action: enterAction }, { type: "close" }] })
                : { type: "noop" },
            shiftEnter: { type: "noop" },
            executable: !!action,
            dangerous: !!node.dangerous,
            risk: node.risk
                ? { level: node.risk.level || "none", activation: node.risk.activation || "normal" }
                : node.dangerous
                    ? { level: "state-change", activation: "confirm" }
                    : null,
            filterable: suppressOwnActions ? false : !!(node.behavior && node.behavior.filterable),
            lazy: !!node.lazy,
            alwaysExpanded: hasExplicitAlwaysExpanded(node)
                ? node.behavior.alwaysExpanded !== false
                : (parentMatchShowsChildren(ev, ctx) || childHasGoodMatch(childRows) || switchHasResidualChildren(ev, ctx)),
            children: childRows || [],
            switchActions: suppressOwnActions ? null : copySwitchActions(node.switchActions, action),
            defaultAction: ActionPolicy.selectedActionMetadata(selectedAction),
            switchState: node.switchState === undefined ? null : node.switchState,
            control: node.control || null,
            presentation: node.presentation || null,
            presentationContext: PresentationContext.toDebug(presCtx),
            metadata: copyMetadata(node.meta, node, action),
            scoreBundle: ev.scoreBundle || null,
            interactions: node.interactions || null
        };

        if (hasReplaceQuery)
            row.recipes = { activate: [["edit-query", { mode: "replace", from: "metadata.replaceQuery" }]] };
        else if (action)
            row.recipes = { activate: [["run-action", { action: "default" }], ["close"]] };

        if (hasReplaceQuery || (!suppressOwnActions && node.behavior && node.behavior.filterable))
            row.recipes = row.recipes || {};
        if (hasReplaceQuery && (!row.recipes || !row.recipes.complete))
            row.recipes = row.recipes || {};
        if (hasReplaceQuery && row.recipes && !row.recipes.complete)
            row.recipes.complete = [["edit-query", { mode: "replace", from: "metadata.replaceQuery" }]];

        return row;
    }

    function displayPolicyFor(node) {
        var chain = Evaluate.collectParentChain(node);
        for (var i = chain.length - 1; i >= 0; i -= 1) {
            var behavior = chain[i].behavior || {};
            if (behavior.displayPolicy) return behavior.displayPolicy;
        }
        return {};
    }

    function breadcrumbTextFor(ev, breadcrumbs, policy, childRows) {
        var mode = policy.breadcrumbMode || "default";
        if (mode === "hidden" || !breadcrumbs.length) return "";
        if (mode === "when-parent-dominates") {
            var childMax = 0;
            for (var i = 0; i < (childRows || []).length; i += 1)
                childMax = Math.max(childMax, Number(childRows[i].ownScore || childRows[i].score || 0));
            if (childMax > 0 && childMax > Number(ev.ownScore || 0)) return "";
        } else if (mode !== "always") {
            return "";
        }
        return breadcrumbs.concat([ev.node.label]).join(" > ");
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

    function visibleFromChildrenOnly(ev) {
        return (!ev.ownScore || ev.ownScore <= 0)
            && ev.children && ev.children.some(function(c) { return c.visible || c.score > 0; });
    }

    function hasExplicitAlwaysExpanded(node) {
        return !!(node && node.behavior && Object.prototype.hasOwnProperty.call(node.behavior, "alwaysExpanded"));
    }

    function childHasGoodMatch(childRows) {
        for (var i = 0; i < (childRows || []).length; i += 1) {
            var child = childRows[i];
            if (child && ((child.ownVisible && (child.ownScore || child.score || 0) > 0) || (child.ownScore || child.score || 0) >= 0.25))
                return true;
        }
        return false;
    }

    function switchHasResidualChildren(ev, ctx) {
        if (!ctx || !ctx.query || !ctx.query.tokens) return false;
        if (!ev || !ev.node || !ev.node.switchActions) return false;
        var children = ev.children || [];
        if (children.length === 0) return false;
        var parentCov = Evidence.coveredTokenIndexes(ev.evidence || [], ctx.query);
        if (Object.keys(parentCov).length >= ctx.query.tokens.length) return false;
        for (var ci = 0; ci < children.length; ci += 1) {
            var child = children[ci];
            if (!child || !child.node) continue;
            var hl = Tokenize.normalizeText(String(child.node.label || "") + " " + (child.node.aliases || []).join(" "));
            for (var tj = 0; tj < ctx.query.tokens.length; tj += 1) {
                if (parentCov[tj]) continue;
                var tn = Tokenize.normalizeText(ctx.query.tokens[tj].raw);
                if (hl.indexOf(tn) === 0 || hl === tn) return true;
            }
        }
        return false;
    }

    function parentMatchShowsChildren(ev, ctx) {
        if (!ev || !ev.node) return false;
        var behavior = ev.node.behavior || {};
        var flattenPolicy = behavior.flattenPolicy || {};
        var groupDisplay = flattenPolicy.groupDisplay || {};
        if (!groupDisplay.showAllChildrenOnParentMatch && !groupDisplay.flattenAllChildrenOnParentMatch)
            return false;
        var minScore = groupDisplay.parentMatchMinScore === undefined ? 0.25 : groupDisplay.parentMatchMinScore;
        return ev.ownVisible && groupDominanceOwnScore(ev, ctx) >= minScore;
    }

    function groupDominanceOwnScore(ev, ctx) {
        var primary = (ev.evidence || []).filter(function(e) {
            if (e.nodeId !== ev.node.id) return false;
            var group = Evidence.evidenceFieldGroup(e.field);
            return group === "primary-text" || group === "path-text" || group === "semantic-text";
        });
        if (!primary.length) return ev.ownScore;
        var score = 0;
        var overlaid = Evidence.overlayEvidence(primary, ctx.query);
        for (var i = 0; i < overlaid.length; i += 1)
            score = 1 - (1 - score) * (1 - Tokenize.clamp(overlaid[i].effective));
        return Tokenize.clamp(Math.min(score, ev.ownScore));
    }

    function copyEvidence(items) {
        return (items || []).map(function(e) {
            return {
                strategy: e.strategy || "",
                field: e.field || "",
                fieldText: e.fieldText || "",
                nodeId: e.nodeId || "",
                originNodeId: e.originNodeId || e.nodeId || "",
                originKind: e.originKind || "self",
                depth: e.depth === undefined ? 0 : Number(e.depth || 0),
                tokenIndex: e.tokenIndex === undefined ? null : e.tokenIndex,
                tokenIndexes: (e.tokenIndexes || []).slice(),
                coverageCount: e.coverageCount || 0,
                exactness: e.exactness || e.strategy || "",
                actionId: e.actionId || null,
                actionRole: e.actionRole || null,
                isExecutable: !!e.isExecutable,
                kind: e.kind || "",
                score: Number(e.score || 0),
                weight: Number(e.weight || 0),
                effective: Number(e.effective || 0),
                ranges: copyRanges(e.ranges),
                reason: e.reason || ""
            };
        });
    }

    function copyRange(r) { return r ? { start: Number(r.start || 0), end: Number(r.end || 0) } : null; }
    function copyRanges(rs) { return (rs || []).map(copyRange).filter(Boolean); }

    function copyPayload(p) {
        if (!p || typeof p !== "object") return p || null;
        var out = {};
        for (var k in p) {
            var v = p[k];
            if (typeof v === "function") continue;
            if (Array.isArray(v)) out[k] = v.slice();
            else if (!v || typeof v !== "object") out[k] = v;
        }
        return out;
    }

    function copyAction(a, isDef) {
        if (!a) return null;
        return {
            id: a.id || "", label: a.label || a.title || a.id || "",
            icon: a.icon || null, default: isDef === undefined ? !!a.default : !!isDef,
            intent: a.intent || null, payload: copyPayload(a.payload)
        };
    }

    function copyActionList(actions, sel) {
        return (actions || []).map(function(a) { return copyAction(a, sel ? a.id === sel.id : a.default); }).filter(Boolean);
    }

    function copySwitchActions(sw, sel) {
        if (!sw) return null;
        var out = {};
        for (var k in sw) out[k] = copyAction(sw[k], sel ? sw[k].id === sel.id : sw[k].default);
        return out;
    }

    function copyMetadata(meta, node, action) {
        var out = {};
        for (var k in meta || {}) {
            if (k === "action") continue;
            var v = meta[k];
            if (Array.isArray(v)) out[k] = v.slice();
            else if (!v || typeof v !== "object") out[k] = v;
        }
        out.nodeId = node.id;
        if (action) out.actionId = action.id || "";
        return out;
    }

    function toDebug(row) {
        if (!row) return null;
        return {
            id: row.id, title: row.title, source: row.source, kind: row.kind,
            score: row.score, ownScore: row.ownScore, ownVisible: row.ownVisible,
            depth: row.depth, placement: row.placement, children: (row.children || []).length,
            actions: (row.actions || []).length,
            hasRecipes: !!row.recipes,
            hasInteractions: !!row.interactions,
            defaultAction: row.defaultAction,
            interactionKeys: row.interactions ? Object.keys(row.interactions) : []
        };
    }
}
