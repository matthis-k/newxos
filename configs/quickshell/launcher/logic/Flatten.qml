pragma Singleton
import QtQml
import Quickshell
import "Tokenize.qml"
import "Evidence.qml"
import "Evaluate.qml"
import "../policies/presentation/"

Singleton {
    id: root

    function decideGroupDisplay(ev, ctx) {
        var presMode = PresentationPolicy.decidePresentation(ev, ctx);
        if (presMode && presMode.mode !== "normal")
            return presMode;

        if (ev.node.switchActions) {
            if (!ev.children || ev.children.length === 0)
                return { mode: "group", showParent: true, children: [] };
            var switchPolicy = PresentationPolicy.groupDisplayPolicy(ev) || {};
            var switchGroupPolicy = switchPolicy.groupDisplay || {};
            var switchMinChildScore = switchGroupPolicy.minChildScore === undefined ? 0.25 : switchGroupPolicy.minChildScore;
            var switchMaxChildren = switchGroupPolicy.maxNestedChildren || switchGroupPolicy.maxFlattenedChildren || 8;

            if (ctx.query.lastTokenEmpty && ev.ownVisible && ev.ownScore >= switchMinChildScore) {
                var browseChildren = ev.children.filter(function(c) {
                    return c.candidate || c.visible;
                }).sort(Evaluate.compareEvaluated).slice(0, switchMaxChildren);
                if (browseChildren.length > 0)
                    return { mode: "nested-group", showParent: true, children: browseChildren };
            }

            var switchChildren = ev.children.filter(function(c) {
                return PresentationPolicy.childPassesVisible(c, ev, ctx);
            }).sort(Evaluate.compareEvaluated).slice(0, switchMaxChildren);
            if (switchChildren.length > 0)
                return { mode: "nested-group", showParent: true, children: switchChildren };
            return { mode: "group", showParent: true, children: [] };
        }

        var policy = PresentationPolicy.groupDisplayPolicy(ev);

        if (ev.node.behavior && ev.node.behavior.filterable) {
            if (ev.ownVisible && policy) {
                var childScore = PresentationPolicy.groupDominanceOwnScore(ev, ctx);
                var visibleChildren = ev.children.filter(function(c) {
                    return PresentationPolicy.childPassesVisible(c, ev, ctx);
                }).sort(Evaluate.compareEvaluated);
                if (visibleChildren.length) {
                    var dominantChildren = visibleChildren.filter(function(c) {
                        return PresentationPolicy.childDominates(c, ev, ctx);
                    });
                    if (dominantChildren.length === 1) {
                        return { mode: "flatten-children", showParent: false, children: dominantChildren };
                    }
                    if (dominantChildren.length > 1) {
                        return { mode: "nested-group", showParent: true, suppressParentActions: true, children: dominantChildren };
                    }
                }
                return { mode: "nested-group", showParent: true, children: ev.children.slice() };
            }
        }

        var hasActions = (ev.node.actionList && ev.node.actionList.length > 0);
        if (!hasActions && ev.children.length > 0) {
            var maxChildren = policy ? (policy.maxNestedChildren || ev.children.length) : ev.children.length;
            return { mode: "flatten-all-children", showParent: false, children: flattenActionableChildren(ev.children, maxChildren) };
        }

        if (!policy)
            return { mode: "normal", showParent: true, children: ev.children };
        var parentScore = PresentationPolicy.groupDominanceOwnScore(ev, ctx);

        if ((policy.showAllChildrenOnParentMatch || policy.flattenAllChildrenOnParentMatch) && parentScore >= policy.parentMatchMinScore)
            return { mode: "nested-group", showParent: true, includeAllChildren: true, children: ev.children.slice(0, policy.maxNestedChildren || ev.children.length) };

        if (policy.committedTokenPrefersGroup && ctx.query.lastTokenEmpty && parentScore >= policy.committedTokenMinParentScore)
            return { mode: "nested-group", showParent: true, children: ev.children.slice(0, policy.maxFlattenedChildren) };

        if (!hasActions && policy.flattenAllChildrenOnParentMatch && parentScore >= policy.parentMatchMinScore)
            return { mode: "flatten-all-children", showParent: false, children: flattenActionableChildren(ev.children, policy.maxNestedChildren || ev.children.length) };
        var visibleChildren = ev.children.filter(function(c) {
            return PresentationPolicy.childPassesVisible(c, ev, ctx);
        }).sort(Evaluate.compareEvaluated);
        if (!visibleChildren.length) {
            return { mode: "group", showParent: true, children: [] };
        }
        var bestChild = visibleChildren[0];
        var dominantChildren = visibleChildren.filter(function(child) {
            return PresentationPolicy.childDominates(child, ev, ctx);
        });
        if (dominantChildren.length === 1) {
            return { mode: "flatten-children", showParent: false, children: dominantChildren };
        }
        if (dominantChildren.length > 1) {
            return { mode: "nested-group", showParent: true, suppressParentActions: true, children: dominantChildren.slice(0, policy.maxFlattenedChildren) };
        }
        if (parentScore >= bestChild.score + policy.parentWinsMargin) {
            return { mode: "group", showParent: true, children: [] };
        }
        if (bestChild.score >= parentScore + policy.childDominatesMargin) {
            return { mode: "flatten-children", showParent: false, children: visibleChildren.slice(0, policy.maxFlattenedChildren) };
        }
        return { mode: "group", showParent: true, children: [] };
    }

    function flattenActionableChildren(children, limit) {
        var out = [];
        function visit(child) {
            if (!child || out.length >= limit)
                return;
            if ((child.node.actionList && child.node.actionList.length) || child.node.switchActions) {
                out.push(child);
                return;
            }
            for (var i = 0; i < (child.children || []).length && out.length < limit; i += 1)
                visit(child.children[i]);
        }
        for (var i = 0; i < (children || []).length && out.length < limit; i += 1)
            visit(children[i]);
        return out;
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

    function copyRange(range) {
        if (!range)
            return null;
        return { start: Number(range.start || 0), end: Number(range.end || 0) };
    }

    function copyRanges(ranges) {
        return (ranges || []).map(copyRange).filter(Boolean);
    }

    function copyEvidence(evidenceItems) {
        return (evidenceItems || []).map(function(e) {
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

    function negativeEvidenceForMissingTokens(ev, ctx) {
        if (!ctx.query || ctx.query.tokens.length <= 1)
            return [];
        var covered = Evidence.coveredTokenIndexes(ev.evidence || [], ctx.query);
        var out = [];
        for (var i = 0; i < ctx.query.tokens.length; i += 1) {
            if (covered[i])
                continue;
            out.push({ strategy: "negative", field: "unmatched-token", fieldText: ctx.query.tokens[i].raw, nodeId: ev.node.id, originNodeId: ev.node.id, originKind: "self", depth: 0, tokenIndex: i, tokenIndexes: [i], coverageCount: 0, exactness: "missing", actionId: null, actionRole: null, isExecutable: false, kind: "negative-unmatched-token", score: -1, weight: 0, effective: 0, ranges: [], reason: "query token has no matching evidence" });
        }
        return out;
    }

    function copyPayload(payload) {
        if (!payload || typeof payload !== "object")
            return payload || null;
        var out = {};
        for (var key in payload) {
            var value = payload[key];
            if (typeof value === "function")
                continue;
            else if (Array.isArray(value))
                out[key] = value.slice();
            else if (!value || typeof value !== "object")
                out[key] = value;
        }
        return out;
    }

    function copyAction(action, isDefault) {
        if (!action)
            return null;
        return {
            id: action.id || "",
            label: action.label || action.title || action.id || "",
            icon: action.icon || null,
            default: isDefault === undefined ? !!action.default : !!isDefault,
            intent: action.intent || null,
            payload: copyPayload(action.payload)
        };
    }

    function copyActionList(actions, selectedAction) {
        return (actions || []).map(function(action) {
            return copyAction(action, selectedAction ? action.id === selectedAction.id : action.default);
        }).filter(Boolean);
    }

    function copySwitchActions(switchActions, selectedAction) {
        if (!switchActions)
            return null;
        var out = {};
        for (var key in switchActions)
            out[key] = copyAction(switchActions[key], selectedAction ? switchActions[key].id === selectedAction.id : switchActions[key].default);
        return out;
    }

    function copyMetadata(meta, node, action) {
        var out = {};
        for (var key in meta || {}) {
            if (key === "action")
                continue;
            var value = meta[key];
            if (Array.isArray(value))
                out[key] = value.slice();
            else if (!value || typeof value !== "object")
                out[key] = value;
        }
        out.nodeId = node.id;
        if (action)
            out.actionId = action.id || "";
        return out;
    }

    function displayPolicyFor(node) {
        var chain = Evaluate.collectParentChain(node);
        for (var i = chain.length - 1; i >= 0; i -= 1) {
            var behavior = chain[i].behavior || {};
            if (behavior.displayPolicy)
                return behavior.displayPolicy;
        }
        return {};
    }

    function breadcrumbTextFor(ev, breadcrumbs, policy, childRows) {
        var mode = policy.breadcrumbMode || "default";
        if (mode === "hidden" || !breadcrumbs.length)
            return "";
        if (mode === "when-parent-dominates") {
            var childMax = 0;
            for (var i = 0; i < (childRows || []).length; i += 1)
                childMax = Math.max(childMax, Number(childRows[i].ownScore || childRows[i].score || 0));
            if (childMax > 0 && childMax > Number(ev.ownScore || 0))
                return "";
        } else if (mode !== "always") {
            return "";
        }
        return breadcrumbs.concat([ev.node.label]).join(" > ");
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

    function visibleFromChildrenOnly(ev) {
        return (!ev.ownScore || ev.ownScore <= 0) && ev.children && ev.children.some(function(child) {
            return child.visible || child.score > 0;
        });
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

    function isDiscoverable(node, ctx) {
        var directive = ctx.directive;
        if (!directive || !directive.active)
            return false;
        if (!ctx.query.isEmpty)
            return false;
        var chain = Evaluate.collectParentChain(node);
        for (var i = 0; i < chain.length; i += 1) {
            var behavior = chain[i].behavior || {};
            if (behavior.displayPolicy && behavior.displayPolicy.discoverable)
                return true;
        }
        return false;
    }

    function parentMatchShowsChildren(ev, ctx) {
        var behavior = ev && ev.node && ev.node.behavior || {};
        var flattenPolicy = behavior.flattenPolicy || {};
        var groupDisplay = flattenPolicy.groupDisplay || {};
        if (!groupDisplay.showAllChildrenOnParentMatch && !groupDisplay.flattenAllChildrenOnParentMatch)
            return false;
        var minScore = groupDisplay.parentMatchMinScore === undefined ? 0.25 : groupDisplay.parentMatchMinScore;
        return ev.ownVisible && PresentationPolicy.groupDominanceOwnScore(ev, ctx) >= minScore;
    }

    function toResultRow(ev, depth, state, ctx, childRows, options) {
        options = options || {};
        var node = ev.node;
        var chain = Evaluate.collectParentChain(node);
        var breadcrumbs = chain.slice(0, -1).map(function(n) { return n.label; });
        var brRoot = chain.find(function(n) { return n.behavior && n.behavior.visualRoot; });
        if (brRoot)
            breadcrumbs = breadcrumbs.slice(chain.indexOf(brRoot));
        var displayPolicy = displayPolicyFor(node);
        var breadcrumbText = breadcrumbTextFor(ev, breadcrumbs, displayPolicy, childRows);
        var action = defaultActionForNode(node, ctx.query, ev.ownScore);
        var suppressOwnActions = action && childRows && childRows.length && ctx.query.tokens.length > 1 && (options.suppressParentActions || visibleFromChildrenOnly(ev));
        if (suppressOwnActions)
            action = null;
        var sourceActions = suppressOwnActions ? [] : (node.actionList || []).slice();
        if (node.switchActions) {
            sourceActions = [node.switchActions.toggle, node.switchActions.on, node.switchActions.off].filter(Boolean);
        }
        var actions = copyActionList(sourceActions, action);
        var enterAction = action ? copyAction(action, true) : null;
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
            iconColor: node.iconColor || null,
            depth: depth,
            score: ev.score,
            ownScore: ev.ownScore,
            inheritedScore: ev.inheritedScore || 0,
            descendantScore: ev.descendantScore || 0,
            ownVisible: !!ev.ownVisible,
            matchDepth: ev.matchDepth === undefined ? depth : ev.matchDepth,
            evidence: copyEvidence((ev.evidence || []).concat(negativeEvidenceForMissingTokens(ev, ctx))),
            selected: state.selectedNodeId === node.id,
            expandable: childRows ? childRows.length > 0 : (ev.children && ev.children.length > 0),
            expanded: state.expandedNodeIds[node.id] || node.kind === "backend",
            breadcrumbs: breadcrumbs,
            breadcrumbText: breadcrumbText,
            display: Object.assign({ breadcrumbText: breadcrumbText }, displayPolicy),
            labelMatches: copyRanges(rangesForField(ev.evidence, "label", node.id)),
            subtitleMatches: copyRanges(rangesForField(ev.evidence, "subtitle", node.id)),
            actions: actions,
            enter: enterAction ? (enterAction.payload && enterAction.payload.replaceQuery ? { type: "sequence", steps: [{ type: "activate", action: enterAction }] } : { type: "sequence", steps: [{ type: "activate", action: enterAction }, { type: "close" }] }) : { type: "noop" },
            shiftEnter: { type: "noop" },
            executable: !!action,
            dangerous: !!node.dangerous,
            risk: node.risk ? {
                level: node.risk.level || "none",
                activation: node.risk.activation || "normal"
            } : node.dangerous ? {
                level: "state-change",
                activation: "confirm"
            } : null,
            filterable: !!(node.behavior && node.behavior.filterable),
            lazy: !!node.lazy,
            alwaysExpanded: hasExplicitAlwaysExpanded(node) ? node.behavior.alwaysExpanded !== false : (parentMatchShowsChildren(ev, ctx) || childHasGoodMatch(childRows)),
            children: childRows || [],
            switchActions: copySwitchActions(node.switchActions, action),
            switchState: node.switchState === undefined ? null : node.switchState,
            control: node.control || null,
            presentation: node.presentation || null,
            metadata: copyMetadata(node.meta, node, action)
        };
    }

    function flattenForUi(evaluatedRoot, state, ctx) {
        var collected = [];
        function structuralDepth(ev) {
            return Math.max(0, Evaluate.collectParentChain(ev.node).length - 2);
        }
        function canInclude(ev) {
            if (ctx.directive && ctx.directive.active && !ev.allowed) return false;
            if (!(ev.visible || ctx.showHidden)) return false;
            if (ev.node.kind === "backend") return false;
            return true;
        }
        function add(ev, depth, sortScore, childEvs, forceInclude, options) {
            if (ev.node.kind !== "root" && (forceInclude || canInclude(ev)))
                collected.push({ ev: ev, depth: depth, sortScore: sortScore === undefined ? ev.score : sortScore, childEvs: childEvs || [], options: options || {} });
        }
        function collect(ev, depth, forceInclude) {
            if (ev.node.kind === "root") {
                for (var i = 0; i < ev.children.length; i += 1) collect(ev.children[i], depth + 1, forceInclude);
                return;
            }
            if (ev.node.kind === "backend") {
                for (var bi = 0; bi < ev.children.length; bi += 1) collect(ev.children[bi], depth, forceInclude);
                return;
            }
            if (!ev.visible && isDiscoverable(ev.node, ctx)) {
                add(ev, depth, 0, [], true);
                return;
            }
            var decision = decideGroupDisplay(ev, ctx);
            if (decision.mode === "flatten-all-children") {
                for (var ai = 0; ai < decision.children.length; ai += 1) {
                    var child = decision.children[ai];
                    if (child.children && child.children.length > 0)
                        collect(child, depth + 1, true);
                    else
                        add(child, depth + 1, child.score, [], true);
                }
                return;
            }
            if (decision.mode === "normal") {
                add(ev, depth, undefined, [], forceInclude);
                for (var n = 0; n < ev.children.length; n += 1) collect(ev.children[n], depth + 1, forceInclude);
                return;
            }
            if (decision.showParent) {
                var childMaxScore = decision.children.length ? Math.max.apply(null, decision.children.map(function(c) { return c.score; })) : 0;
                var score = decision.mode === "nested-group" ? Math.max(0, Math.max(ev.score, childMaxScore) - 0.015) : ev.score;
                if (decision.mode === "nested-group") {
                    add(ev, depth, score, decision.children, forceInclude, { suppressParentActions: !!decision.suppressParentActions, includeAllChildren: !!decision.includeAllChildren });
                    return;
                }
            if (decision.mode !== "group" || ev.ownScore > 0 || ev.ownVisible)
                    add(ev, depth, score, [], forceInclude);
            }
            if (decision.mode === "group")
                return;
            if (decision.mode === "flatten-children") {
                for (var di = 0; di < decision.children.length; di += 1)
                    add(decision.children[di], depth, decision.children[di].score, [], true);
                return;
            }
            for (var di = 0; di < decision.children.length; di += 1)
                collect(decision.children[di], depth + 1, forceInclude);
        }
        collect(evaluatedRoot, -1, false);
        collected.sort(function(a, b) {
            var delta = b.sortScore - a.sortScore;
            if (Math.abs(delta) > 0.0001) return delta;
            var priorityDelta = (b.ev.node.behavior && b.ev.node.behavior.flattenPolicy && b.ev.node.behavior.flattenPolicy.priority || 0) - (a.ev.node.behavior && a.ev.node.behavior.flattenPolicy && a.ev.node.behavior.flattenPolicy.priority || 0);
            if (priorityDelta !== 0) return priorityDelta;
            var structuralDepthDelta = structuralDepth(a.ev) - structuralDepth(b.ev);
            if (structuralDepthDelta !== 0) return structuralDepthDelta;
            return a.depth - b.depth;
        });
        function buildChildTree(ev, currentDepth, maxDepth, includeAllChildren) {
            if (maxDepth <= 0 || !ev.children)
                return [];
            var filtered = ev.children.filter(function(c) {
                return c.allowed && c.node.kind !== "backend" && (includeAllChildren || c.visible || c.score >= 0.25);
            });
            var profile = ev.node && ev.node.evaluationProfile && ev.node.evaluationProfile.profile;
            if (profile && profile.childVisible && profile.childVisible.length) {
                filtered = filtered.filter(function(c) {
                    return PresentationPolicy.childPassesVisible(c, ev, ctx);
                });
            }
            return buildChildRows(filtered, currentDepth, maxDepth, includeAllChildren);
        }
        function buildChildRows(children, currentDepth, maxDepth, includeAllChildren) {
            if (maxDepth <= 0 || !children)
                return [];
            var filtered = children.filter(function(c) { return c.allowed && c.node.kind !== "backend" && (includeAllChildren || c.visible || c.score >= 0.25); });
            return filtered.map(function(child) {
                var grandChildren = buildChildTree(child, currentDepth + 1, maxDepth - 1, includeAllChildren);
                return toResultRow(child, currentDepth + 1, state, ctx, grandChildren);
            });
        }

        var maxTreeDepth = ctx.maxTreeDepth >= 0 ? ctx.maxTreeDepth : 3;
        return collected.map(function(item) {
            var includeAllChildren = item.options && item.options.includeAllChildren;
            var childRows;
            if (item.childEvs != null) {
                childRows = item.childEvs.length ? buildChildRows(item.childEvs, item.depth, maxTreeDepth, includeAllChildren) : [];
            } else {
                childRows = buildChildTree(item.ev, item.depth, maxTreeDepth, false);
            }
            return toResultRow(item.ev, item.depth, state, ctx, childRows, item.options);
        });
    }

}
