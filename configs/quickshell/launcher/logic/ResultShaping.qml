pragma Singleton
import QtQml
import Quickshell
import "Tokenize.qml"
import "Evidence.qml"
import "Evaluate.qml"
import "PolicyChain.qml"
import "ResultSemantics.qml"
import "TakeoverEngine.qml"
import "../policies/presentation/"
import "CompositeSearchPolicyRegistry.js" as JsRegistry

Singleton {
    id: root

    function shape(evaluatedRoot, state, ctx) {
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

        function makeShaped(ev, depth, sortScore, childEvs, forceInclude, options, placement, decision) {
            if (ev.node.kind !== "root" && (forceInclude || canInclude(ev))) {
                collected.push({
                    ev: ev,
                    depth: depth,
                    sortScore: sortScore === undefined ? ev.score : sortScore,
                    childEvs: childEvs || [],
                    placement: placement || "standalone",
                    decision: decision || { placement: placement || "standalone", mode: "normal", showParent: true },
                    presentationHints: (decision && decision.presentationHints) || {},
                    options: options || {},
                    semantics: ResultSemantics.build(ev, decision || { placement: placement || "standalone", mode: "normal", showParent: true }, placement || "standalone", ctx)
                });
            }
        }

        function isDiscoverable(node) {
            var directive = ctx.directive;
            if (!directive || !directive.active) return false;
            if (!ctx.query.isEmpty) return false;
            var chain = Evaluate.collectParentChain(node);
            for (var i = 0; i < chain.length; i += 1) {
                var behavior = chain[i].behavior || {};
                if (behavior.displayPolicy && behavior.displayPolicy.discoverable) return true;
            }
            return false;
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
            if (!ev.visible && isDiscoverable(ev.node)) {
                makeShaped(ev, depth, 0, [], true, {}, "standalone", { placement: "standalone", mode: "normal", showParent: true });
                return;
            }
            var decision = decidePlacement(ev, ctx);
            if (decision.mode === "flatten-all-children") {
                for (var ai = 0; ai < decision.children.length; ai += 1) {
                    var child = decision.children[ai];
                    if (child.children && child.children.length > 0)
                        collect(child, depth + 1, true);
                    else
                        makeShaped(child, depth + 1, child.score, [], true, {}, "flattened", { placement: "flattened", mode: "flatten-all-children", showParent: false });
                }
                return;
            }
            if (decision.mode === "normal") {
                makeShaped(ev, depth, undefined, [], forceInclude, {}, "standalone", decision);
                for (var n = 0; n < ev.children.length; n += 1) collect(ev.children[n], depth + 1, forceInclude);
                return;
            }
            if (decision.showParent) {
                var childMaxScore = decision.children.length
                    ? Math.max.apply(null, decision.children.map(function(c) { return c.score; }))
                    : 0;
                var score = decision.mode === "nested-group"
                    ? Math.max(0, Math.max(ev.score, childMaxScore) - 0.015)
                    : ev.score;
                if (decision.mode === "nested-group") {
                    makeShaped(ev, depth, score, decision.children, forceInclude,
                        { suppressParentActions: !!decision.suppressParentActions, includeAllChildren: !!decision.includeAllChildren },
                        "nested-group", decision);
                    return;
                }
                if (decision.mode !== "group" || ev.ownScore > 0 || ev.ownVisible)
                    makeShaped(ev, depth, score, [], forceInclude, {}, decision.placement || "group", decision);
            }
            if (decision.mode === "group") return;
            if (decision.mode === "flatten-children") {
                for (var di = 0; di < decision.children.length; di += 1)
                    makeShaped(decision.children[di], depth, decision.children[di].score, [], true, {}, "promoted-child", { placement: "promoted-child", mode: "flatten-children", showParent: false, parentDecision: decision });
                return;
            }
            for (var ci = 0; ci < decision.children.length; ci += 1)
                collect(decision.children[ci], depth + 1, forceInclude);
        }

        collect(evaluatedRoot, -1, false);

        collected.sort(function(a, b) {
            var delta = b.sortScore - a.sortScore;
            if (Math.abs(delta) > 0.0001) return delta;
            var priorityDelta = (b.ev.node.behavior && b.ev.node.behavior.flattenPolicy && b.ev.node.behavior.flattenPolicy.priority || 0)
                - (a.ev.node.behavior && a.ev.node.behavior.flattenPolicy && a.ev.node.behavior.flattenPolicy.priority || 0);
            if (priorityDelta !== 0) return priorityDelta;
            var structuralDepthDelta = structuralDepth(a.ev) - structuralDepth(b.ev);
            if (structuralDepthDelta !== 0) return structuralDepthDelta;
            return a.depth - b.depth;
        });

        return {
            shaped: collected,
            maxTreeDepth: ctx.maxTreeDepth >= 0 ? ctx.maxTreeDepth : 3
        };
    }

    function decidePlacement(ev, ctx) {
        var takeoverClaims = ev.children && ev.children.length > 0
            ? TakeoverEngine.evaluateTakeoverRequests(ev, ev.children, ctx)
            : [];
        var takeoverDecision = takeoverClaims.length > 0
            ? TakeoverEngine.decideTakeover(ev, takeoverClaims, ctx)
            : null;

        function _applyExpandRetain(d) {
            var profile = (ev.node.evaluationProfile && ev.node.evaluationProfile.profile) || {};
            var expandNames = profile.expand || [];
            var retainNames = profile.retainParent || [];
            var expandResult = expandNames.length > 0
                ? PolicyChain.run(expandNames, function(name, spec) {
                    var policy = PolicyChain.lookupPolicy(JsRegistry.expand, spec);
                    if (!policy) return null;
                    return policy.apply(ev, ctx, spec && spec.args);
                }, "first-wins") : null;
            var retainResult = retainNames.length > 0
                ? PolicyChain.run(retainNames, function(name, spec) {
                    var policy = PolicyChain.lookupPolicy(JsRegistry.retainParent, spec);
                    if (!policy) return null;
                    return policy.apply(ev, ctx, spec && spec.args);
                }, "first-wins") : null;
            var out = Object.assign({}, d);
            if (expandResult && expandResult.value && expandResult.value.expand) {
                out._expandResult = expandResult.value;
            }
            if (retainResult && retainResult.value && retainResult.value.retain === false) {
                out.showParent = false;
                out._suppressedRetain = true;
            }
            return out;
        }

        function _d(obj) {
            var withTakeover = attachTakeover(obj, takeoverClaims, takeoverDecision);
            return _applyExpandRetain(withTakeover);
        }

        // --- PRIMITIVE-FIRST PATH (new) ---
        // When expand/retain/takeover policies are configured, let them drive placement
        // before falling back to the old PresentationPolicy-dominated logic below.
        // Compatibility shim: old logic runs when no primitive signals are active.
        var _pfProfile = (ev.node.evaluationProfile && ev.node.evaluationProfile.profile) || {};
        var _pfExpand = _pfProfile.expand || [];
        var _pfRetain = _pfProfile.retainParent || [];
        var _pfExpandResult = null;
        if (_pfExpand.length > 0) {
            _pfExpandResult = PolicyChain.run(_pfExpand, function(name, spec) {
                var policy = PolicyChain.lookupPolicy(JsRegistry.expand, spec);
                if (!policy) return null;
                return policy.apply(ev, ctx, spec && spec.args);
            }, "first-wins");
        }
        if (_pfExpandResult && _pfExpandResult.value && _pfExpandResult.value.expand && ev.children && ev.children.length > 0) {
            var _pfKids = ev.children.filter(function(c) {
                return c.allowed && (c.visible || c.score >= 0.25);
            }).sort(Evaluate.compareEvaluated);
            if (_pfKids.length > 0) {
                var _pfShowParent = true;
                if (_pfRetain.length > 0) {
                    var _pfRetainResult = PolicyChain.run(_pfRetain, function(name, spec) {
                        var policy = PolicyChain.lookupPolicy(JsRegistry.retainParent, spec);
                        if (!policy) return null;
                        return policy.apply(ev, ctx, spec && spec.args);
                    }, "first-wins");
                    if (_pfRetainResult && _pfRetainResult.value && _pfRetainResult.value.retain === false)
                        _pfShowParent = false;
                }
                return _d({
                    placement: "nested-group",
                    mode: "nested-group",
                    showParent: _pfShowParent,
                    suppressParentActions: false,
                    children: _pfKids
                });
            }
        }
        // --- END PRIMITIVE-FIRST ---

        var presMode = PresentationPolicy.decidePresentation(ev, ctx);
        if (presMode && presMode.mode !== "normal")
            return _d(Object.assign({ placement: placementForMode(presMode.mode) }, presMode));

        if (ev.node.switchActions) {
            if (!ev.children || ev.children.length === 0)
                return _d({ placement: "group", mode: "group", showParent: true, children: [] });
            var switchPolicy = PresentationPolicy.groupDisplayPolicy(ev) || {};
            var switchGroupPolicy = switchPolicy.groupDisplay || {};
            var switchMinChildScore = switchGroupPolicy.minChildScore === undefined ? 0.25 : switchGroupPolicy.minChildScore;
            var switchMaxChildren = switchGroupPolicy.maxNestedChildren || switchGroupPolicy.maxFlattenedChildren || 8;

            if (ctx.query.lastTokenEmpty && ev.ownVisible && ev.ownScore >= switchMinChildScore) {
                var browseChildren = ev.children.filter(function(c) {
                    return c.candidate || c.visible;
                }).sort(Evaluate.compareEvaluated).slice(0, switchMaxChildren);
                if (browseChildren.length > 0)
                    return _d({ placement: "nested-group", mode: "nested-group", showParent: true, children: browseChildren });
            }

            var switchChildren = ev.children.filter(function(c) {
                return PresentationPolicy.childPassesVisible(c, ev, ctx);
            }).sort(Evaluate.compareEvaluated).slice(0, switchMaxChildren);
            if (switchChildren.length > 0)
                return _d({ placement: "nested-group", mode: "nested-group", showParent: true, children: switchChildren });
            return _d({ placement: "group", mode: "group", showParent: true, children: [] });
        }

        var policy = PresentationPolicy.groupDisplayPolicy(ev);

        if (ev.node.behavior && ev.node.behavior.filterable) {
            if (ev.ownVisible && policy) {
                var filterableMaxChildren = policy.maxNestedChildren || policy.maxFlattenedChildren || ev.children.length;
                var visibleChildren = ev.children.filter(function(c) {
                    return PresentationPolicy.childPassesVisible(c, ev, ctx);
                }).sort(Evaluate.compareEvaluated);
                if (visibleChildren.length) {
                    var dominantChildren = visibleChildren.filter(function(c) {
                        return PresentationPolicy.childDominates(c, ev, ctx);
                    });
                    if (dominantChildren.length === 1)
                        return _d({ placement: "promoted-child", mode: "flatten-children", showParent: false, children: dominantChildren });
                    if (dominantChildren.length > 1)
                        return _d({ placement: "nested-group", mode: "nested-group", showParent: true, suppressParentActions: true, children: dominantChildren.slice(0, filterableMaxChildren) });
                    return _d({ placement: "nested-group", mode: "nested-group", showParent: true, children: visibleChildren.slice(0, filterableMaxChildren) });
                }
                if (ctx.query.lastTokenEmpty)
                    return _d({ placement: "nested-group", mode: "nested-group", showParent: true, children: ev.children.slice(0, filterableMaxChildren) });
                return _d({ placement: "group", mode: "group", showParent: true, children: [] });
            }
        }

        var hasActions = (ev.node.actionList && ev.node.actionList.length > 0);
        if (!hasActions && ev.children.length > 0) {
            var maxChildren = policy ? (policy.maxNestedChildren || ev.children.length) : ev.children.length;
            return _d({ placement: "flattened", mode: "flatten-all-children", showParent: false, children: flattenActionableChildren(ev.children, maxChildren) });
        }

        if (!policy)
            return _d({ placement: "standalone", mode: "normal", showParent: true, children: ev.children });
        var parentScore = PresentationPolicy.groupDominanceOwnScore(ev, ctx);

        if ((policy.showAllChildrenOnParentMatch || policy.flattenAllChildrenOnParentMatch) && parentScore >= policy.parentMatchMinScore)
            return _d({ placement: "nested-group", mode: "nested-group", showParent: true, includeAllChildren: true, children: ev.children.slice(0, policy.maxNestedChildren || ev.children.length) });

        if (policy.committedTokenPrefersGroup && ctx.query.lastTokenEmpty && parentScore >= policy.committedTokenMinParentScore)
            return _d({ placement: "nested-group", mode: "nested-group", showParent: true, children: ev.children.slice(0, policy.maxFlattenedChildren) });

        if (!hasActions && policy.flattenAllChildrenOnParentMatch && parentScore >= policy.parentMatchMinScore)
            return _d({ placement: "flattened", mode: "flatten-all-children", showParent: false, children: flattenActionableChildren(ev.children, policy.maxNestedChildren || ev.children.length) });

        var visibleChildren = ev.children.filter(function(c) {
            return PresentationPolicy.childPassesVisible(c, ev, ctx);
        }).sort(Evaluate.compareEvaluated);

        if (!visibleChildren.length)
            return _d({ placement: "group", mode: "group", showParent: true, children: [] });

        var dominantChildren = visibleChildren.filter(function(c) {
            return PresentationPolicy.childDominates(c, ev, ctx);
        });

        if (dominantChildren.length === 1)
            return _d({ placement: "promoted-child", mode: "flatten-children", showParent: false, children: dominantChildren });

        if (dominantChildren.length > 1)
            return _d({ placement: "nested-group", mode: "nested-group", showParent: true, suppressParentActions: true, children: dominantChildren.slice(0, policy.maxFlattenedChildren) });

        var bestChild = visibleChildren[0];
        if (parentScore >= bestChild.score + policy.parentWinsMargin)
            return _d({ placement: "group", mode: "group", showParent: true, children: [] });

        if (bestChild.score >= parentScore + policy.childDominatesMargin)
            return _d({ placement: "flattened", mode: "flatten-children", showParent: false, children: visibleChildren.slice(0, policy.maxFlattenedChildren) });

        return _d({ placement: "group", mode: "group", showParent: true, children: [] });
    }

    function attachTakeover(decision, claims, takeoverDecision) {
        if (!takeoverDecision) return decision;
        return Object.assign({}, decision, {
            takeover: {
                claims: claims,
                decision: takeoverDecision
            }
        });
    }

    function flattenActionableChildren(children, limit) {
        var out = [];
        function visit(child) {
            if (!child || out.length >= limit) return;
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

    function placementForMode(mode) {
        switch (mode) {
        case "flatten-children": return "promoted-child";
        case "flatten-all-children": return "flattened";
        case "nested-group": return "nested-group";
        case "group": return "group";
        case "normal": return "standalone";
        default: return mode || "standalone";
        }
    }

    function placementLabel(placement) {
        switch (placement) {
        case "hidden": return "hidden";
        case "standalone": return "standalone row";
        case "group": return "group header (children hidden)";
        case "filtered-group": return "filtered group";
        case "group-child": return "child of a group";
        case "flattened": return "flattened (no parent)";
        case "promoted-child": return "promoted to standalone";
        case "nested-group": return "nested group with visible children";
        default: return "unknown";
        }
    }

    function buildChildTree(ev, currentDepth, maxDepth, includeAllChildren) {
        if (maxDepth <= 0 || !ev.children) return [];
        return buildChildRows(ev.children, currentDepth, maxDepth, includeAllChildren);
    }

    function buildChildRows(children, currentDepth, maxDepth, includeAllChildren) {
        if (maxDepth <= 0 || !children) return [];
        var filtered = children.filter(function(c) {
            return c.allowed && c.node.kind !== "backend" && (includeAllChildren || c.visible || c.score >= 0.25);
        });
        return filtered.map(function(child) {
            var grandChildren = buildChildTree(child, currentDepth + 1, maxDepth - 1, includeAllChildren);
            return { ev: child, depth: currentDepth + 1, children: grandChildren };
        });
    }

    function toDebug(shapedResult) {
        if (!shapedResult || !shapedResult.shaped) return [];
        return shapedResult.shaped.map(function(item) {
            return {
                title: item.ev.node.label,
                nodeId: item.ev.node.id,
                score: item.sortScore,
                depth: item.depth,
                placement: item.placement,
                childCount: (item.childEvs || []).length,
                showParent: item.decision ? item.decision.showParent : true,
                mode: item.decision ? item.decision.mode : "normal",
                semantics: ResultSemantics.toDebug(item.semantics)
            };
        });
    }
}
