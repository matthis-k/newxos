pragma Singleton
import QtQml
import Quickshell
import "Tokenize.qml"
import "Evidence.qml"
import "Evaluate.qml"
import "PolicyChain.qml"
import "ResultSemantics.qml"
import "TakeoverEngine.qml"
import "CompositeSearchPolicyRegistry.js" as JsRegistry

Singleton {
    id: root

    function initPolicyTrace(ev, ctx) {
        if (!ev || !ev.node || !ev.node.id || !ctx._policyTrace) return;
        var nid = ev.node.id;
        if (!ctx._policyTrace[nid]) ctx._policyTrace[nid] = {};
    }

    function tracePolicyDecision(ev, ctx, kind, name, returned, effect, reasons) {
        if (!ev || !ev.node || !ev.node.id || !ctx._policyTrace) return;
        var nid = ev.node.id;
        if (!ctx._policyTrace[nid]) ctx._policyTrace[nid] = {};
        if (!ctx._policyTrace[nid][kind]) {
            ctx._policyTrace[nid][kind] = {
                kind: kind,
                evaluated: [],
                aggregate: null,
                final: null
            };
        }
        ctx._policyTrace[nid][kind].evaluated.push({
            name: String(name || kind),
            priority: 0,
            enabled: true,
            returned: returned !== undefined ? returned : null,
            effect: String(effect || "no-op"),
            reasons: (reasons || []).slice()
        });
    }

    function traceFinalDecision(ev, ctx, kind, value, reasons) {
        if (!ev || !ev.node || !ev.node.id || !ctx._policyTrace) return;
        var nid = ev.node.id;
        if (!ctx._policyTrace[nid]) ctx._policyTrace[nid] = {};
        if (!ctx._policyTrace[nid][kind]) {
            ctx._policyTrace[nid][kind] = { kind: kind, evaluated: [], aggregate: null, final: null };
        }
        ctx._policyTrace[nid][kind].final = {
            value: value,
            reasons: (reasons || []).slice()
        };
    }

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
            if (ev && ev.node && ev.node.id && ctx._decisionTrace) {
                var nid = ev.node.id;
                var expandFinal = ctx._policyTrace && ctx._policyTrace[nid] && ctx._policyTrace[nid].expand && ctx._policyTrace[nid].expand.final;
                var retainFinal = ctx._policyTrace && ctx._policyTrace[nid] && ctx._policyTrace[nid].retain && ctx._policyTrace[nid].retain.final;
                var takeoverFinal = ctx._policyTrace && ctx._policyTrace[nid] && ctx._policyTrace[nid].takeover && ctx._policyTrace[nid].takeover.final;
                ctx._decisionTrace[nid] = {
                    nodeId: nid,
                    visibility: { value: { visible: ev.visible }, reasons: [{ code: "visibility", text: "visible=" + ev.visible + " ownVisible=" + ev.ownVisible }] },
                    placement: { value: decision.placement || decision.mode || "unknown", reasons: [{ code: "placement", text: "mode=" + (decision.mode || "normal") + " showParent=" + (decision.showParent !== false) + " placement=" + (decision.placement || decision.mode || "unknown") }] },
                    flattening: { value: { flatten: decision.mode === "flatten-children" || decision.mode === "flatten-all-children", mode: decision.mode || "normal" }, reasons: [{ code: "flattening", text: "mode=" + (decision.mode || "normal") }] },
                    breadcrumbs: null,
                    defaultAction: null,
                    childVisibility: null,
                    _expand: expandFinal || null,
                    _retain: retainFinal || null,
                    _takeover: takeoverFinal || null
                };
                traceFinalDecision(ev, ctx, "placement", { placement: decision.placement || decision.mode || "unknown", mode: decision.mode || "normal", showParent: decision.showParent !== false }, [{ code: "placement_decided", text: "final placement=" + (decision.placement || decision.mode || "unknown") + " mode=" + (decision.mode || "normal") }]);
            }
            if (decision.mode === "flatten-all-children") {
                for (var ai = 0; ai < decision.children.length; ai += 1) {
                    var child = decision.children[ai];
                    if (child.children && child.children.length > 0)
                        collect(child, depth + 1, true);
                    else if (child.visible || child.score >= 0.25)
                        makeShaped(child, depth + 1, child.score, [], true, {}, "flattened", { placement: "flattened", mode: "flattened", showParent: true });
                }
                return;
            }
            if (decision.mode === "normal") {
                if (forceInclude || ev.ownVisible || ev.ownScore > 0 || (ev.children && ev.children.some(function(c) { return c.visible || c.score >= 0.25; }))) {
                    makeShaped(ev, depth, undefined, [], forceInclude, {}, "standalone", decision);
                }
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
                for (var di = 0; di < decision.children.length; di += 1) {
                    var fc = decision.children[di];
                    if (fc.visible || fc.score >= 0.25)
                        makeShaped(fc, depth, fc.score, [], true, {}, "promoted-child", { placement: "promoted-child", mode: "promoted-child", showParent: true });
                }
                return;
            }
            for (var ci = 0; ci < decision.children.length; ci += 1)
                collect(decision.children[ci], depth + 1, forceInclude);
        }

        collect(evaluatedRoot, -1, false);

        collected.sort(function(a, b) {
            var delta = b.sortScore - a.sortScore;
            if (Math.abs(delta) > 0.0001) return delta;
            var structuralDepthDelta = structuralDepth(a.ev) - structuralDepth(b.ev);
            if (structuralDepthDelta !== 0) return structuralDepthDelta;
            return a.depth - b.depth;
        });

        return {
            shaped: collected,
            maxTreeDepth: ctx.maxTreeDepth >= 0 ? ctx.maxTreeDepth : 3
        };
    }

    function evaluatePolicies(ev, ctx, names, registry) {
        if (!names || names.length === 0) return null;
        initPolicyTrace(ev, ctx);
        return PolicyChain.run(names, function(name, spec) {
            var policy = PolicyChain.lookupPolicy(registry, spec);
            if (!policy) return null;
            return policy.apply(ev, ctx, spec && spec.args);
        }, "first-wins");
    }

    function decidePlacement(ev, ctx) {
        var profile = (ev.node.evaluationProfile && ev.node.evaluationProfile.profile) || {};
        var expandNames = profile.expand || [];
        var retainNames = profile.retainParent || [];

        var takeoverClaims = ev.children && ev.children.length > 0
            ? TakeoverEngine.evaluateTakeoverRequests(ev, ev.children, ctx)
            : [];
        var takeoverDecision = takeoverClaims.length > 0
            ? TakeoverEngine.decideTakeover(ev, takeoverClaims, ctx)
            : null;

        initPolicyTrace(ev, ctx);
        if (takeoverClaims.length > 0) {
            tracePolicyDecision(ev, ctx, "takeover", "takeover-claims", takeoverClaims.map(function(c) { return { claimantId: c.claimantId, kind: c.kind, strength: c.strength }; }), takeoverDecision && takeoverDecision.accepted ? "accepted" : "rejected", [{ code: "takeover_result", text: "accepted=" + (takeoverDecision && takeoverDecision.accepted) + " representation=" + (takeoverDecision && takeoverDecision.representation || "") }]);
        }
        if (takeoverDecision && takeoverDecision.accepted) {
            traceFinalDecision(ev, ctx, "takeover", { accepted: true, representation: takeoverDecision.representation, retainParent: takeoverDecision.retainParent !== false, selectedOwnerId: takeoverDecision.selectedOwnerId }, [{ code: "takeover_accepted", text: "Takeover accepted: " + takeoverDecision.representation + " by " + (takeoverDecision.selectedOwnerId || "") }]);
        } else if (takeoverClaims.length > 0) {
            traceFinalDecision(ev, ctx, "takeover", { accepted: false, reason: takeoverDecision ? takeoverDecision.reason : "no decision" }, [{ code: "takeover_rejected", text: "Takeover rejected: " + (takeoverDecision ? takeoverDecision.reason : "no decision") }]);
        }

        function _d(obj) {
            return attachTakeover(obj, takeoverClaims, takeoverDecision);
        }

        function eligibleChildren(children, options) {
            var opts = options || {};
            var includeAll = opts.includeAllChildren === true;
            return (children || []).filter(function(c) {
                if (!c.allowed) return false;
                if (includeAll) return true;
                return c.visible || c.score >= (opts.minScore === undefined ? 0.25 : opts.minScore);
            }).sort(Evaluate.compareEvaluated);
        }

        // 1. Takeover
        if (takeoverDecision && takeoverDecision.accepted) {
            var takeoverChildren = eligibleChildren(ev.children, {
                includeAllChildren: takeoverDecision.includeAllChildren === true
            });
            if (takeoverChildren.length > 0) {
                var takeoverShowParent = takeoverDecision.retainParent !== false;
                if (takeoverDecision.representation === "flatten" || takeoverDecision.representation === "promote-child") {
                    traceFinalDecision(ev, ctx, "takeover", { accepted: true, representation: "flatten", children: takeoverChildren.length }, [{ code: "takeover_flatten", text: "Takeover flattens to " + takeoverChildren.length + " children" }]);
                    return _d({
                        placement: takeoverChildren.length === 1 ? "promoted-child" : "flattened",
                        mode: takeoverChildren.length === 1 ? "flatten-children" : "flatten-all-children",
                        showParent: takeoverShowParent,
                        suppressParentActions: takeoverDecision.suppressParentActions || false,
                        children: takeoverChildren
                    });
                }
                if (takeoverDecision.representation === "nested-group") {
                    traceFinalDecision(ev, ctx, "takeover", { accepted: true, representation: "nested-group", children: takeoverChildren.length }, [{ code: "takeover_nested_group", text: "Takeover nested-group with " + takeoverChildren.length + " children" }]);
                    return _d({
                        placement: "nested-group",
                        mode: "nested-group",
                        showParent: takeoverShowParent,
                        suppressParentActions: takeoverDecision.suppressParentActions || false,
                        children: takeoverChildren
                    });
                }
            }
        }

        // 2. Expand
        var expandResult = null;
        if (expandNames.length > 0) {
            var expandRaw = evaluatePolicies(ev, ctx, expandNames, JsRegistry.expand);
            expandResult = expandRaw && expandRaw.value;
            if (expandResult && expandResult.expand && ev.children && ev.children.length > 0) {
                var expandKids = eligibleChildren(ev.children, {
                    includeAllChildren: !!expandResult.includeAllChildren,
                    minScore: expandResult.minScore === undefined ? 0 : expandResult.minScore
                });
                if (expandResult.maxChildren !== undefined)
                    expandKids = expandKids.slice(0, expandResult.maxChildren);
                if (expandKids.length > 0) {
                    var expandShowParent = true;
                    if (retainNames.length > 0) {
                        var retainRaw = evaluatePolicies(ev, ctx, retainNames, JsRegistry.retainParent);
                        var retainResult = retainRaw && retainRaw.value;
                        if (retainResult && retainResult.retain === false)
                            expandShowParent = false;
                        traceFinalDecision(ev, ctx, "retain", { retain: expandShowParent }, [{ code: "retain_decision", text: "showParent=" + expandShowParent }]);
                    }
                    traceFinalDecision(ev, ctx, "expand", { expand: true, children: expandKids.length, includeAllChildren: !!expandResult.includeAllChildren }, [{ code: "expand_decision", text: "Expanded " + expandKids.length + " children" }]);
                    return _d({
                        placement: "nested-group",
                        mode: "nested-group",
                        showParent: expandShowParent,
                        suppressParentActions: false,
                        includeAllChildren: !!expandResult.includeAllChildren,
                        children: expandKids
                    });
                }
            }
        }

        // 3. Retain-only (no expand or expand produced no children)
        if (retainNames.length > 0) {
            var retainRaw = evaluatePolicies(ev, ctx, retainNames, JsRegistry.retainParent);
            var retainResult = retainRaw && retainRaw.value;
            if (retainResult && retainResult.retain === false && ev.children && ev.children.length > 0) {
                var retainKids = eligibleChildren(ev.children, { includeAllChildren: true });
                traceFinalDecision(ev, ctx, "retain", { retain: false, children: retainKids.length }, [{ code: "retain_suppress", text: "Retain suppressed parent, flattening " + retainKids.length + " children" }]);
                return _d({
                    placement: "flattened",
                    mode: "flatten-all-children",
                    showParent: false,
                    suppressParentActions: false,
                    children: flattenActionableChildren(retainKids, 16)
                });
            }
        }

        // 4. Default
        return _d({
            placement: "standalone",
            mode: "normal",
            showParent: true,
            children: ev.children || []
        });
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
