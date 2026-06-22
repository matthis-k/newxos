pragma Singleton
import QtQuick
import Quickshell
import "../../logic/"
import "../../logic/CompositeSearchPolicyRegistry.js" as JsRegistry
import "PresentationPresets.qml"

// COMPATIBILITY LAYER — old presentation/groupOptions logic.
//
// New nodes with explicit primitive policies (expand, retainParent, takeover)
// are handled by the PRIMITIVE-FIRST path in ResultShaping.decidePlacement.
// This file is the fallback for nodes without primitive policies and should
// not be the canonical source of truth for new behavior.
//
// New launcher behavior must be expressed through primitive policies:
// tokenFlow, expand, retainParent, takeoverRequest, takeoverAccept,
// defaultAction, and riskGate. Do not add new behavior here through
// groupOptions, flattenPolicy, showAllChildrenOnParentMatch,
// flattenAllChildrenOnParentMatch, committedTokenPrefersGroup, or childBypass.
//
// Migration target: move node-specific placement logic out of PresentationPolicy
// into per-kind primitive policies or backend-specific profiles.
Singleton {
    id: root
    readonly property var defaultChildVisible: ["visible-flag"]
    readonly property var defaultChildBypass: ["own-score-beats-parent", "score-dominates:0.03"]

    function childProfile(ev) {
        return (ev.node.evaluationProfile || {}).profile || {};
    }

    // COMPATIBILITY: use for nodes without explicit expand/takeover primitives.
    // Determines visibility of child rows under a group parent.
    function childPassesVisible(childEval, parentEval, ctx) {
        var profile = childProfile(parentEval);
        var names = profile.childVisible || defaultChildVisible;
        var pnid = parentEval && parentEval.node && parentEval.node.id;
        if (pnid && ctx && ctx._policyTrace && !ctx._policyTrace[pnid]) ctx._policyTrace[pnid] = {};
        return PolicyChain.run(names, function(name, spec) {
            var policy = PolicyChain.lookupPolicy(JsRegistry.childVisible, spec);
            if (!policy) return false;
            return policy.apply(childEval, parentEval, ctx, spec && spec.args);
        }, "childVisible", function(tr) {
            if (!pnid || !ctx || !ctx._policyTrace) return;
            if (!ctx._policyTrace[pnid]) return;
            if (!ctx._policyTrace[pnid].childVisible) {
                ctx._policyTrace[pnid].childVisible = { kind: "childVisible", evaluated: [], aggregate: null, final: null };
            }
            ctx._policyTrace[pnid].childVisible.evaluated.push({
                name: tr.name, priority: tr.priority || 0, enabled: true,
                args: tr.args,
                returned: tr.returned,
                effect: tr.effect || "combined",
                reasons: tr.returned && tr.returned.reasons ? tr.returned.reasons.slice() : []
            });
        }).value;
    }

    // COMPATIBILITY: determines whether a child visually "dominates" its parent,
    // meaning the child should be promoted or flatten the parent.
    function childDominates(childEval, parentEval, ctx) {
        var profile = childProfile(parentEval);
        var names = profile.childBypass || defaultChildBypass;
        var pnid = parentEval && parentEval.node && parentEval.node.id;
        if (pnid && ctx && ctx._policyTrace && !ctx._policyTrace[pnid]) ctx._policyTrace[pnid] = {};
        return PolicyChain.run(names, function(name, spec) {
            var policy = PolicyChain.lookupPolicy(JsRegistry.childBypass, spec);
            if (!policy) return null;
            return policy.apply(childEval, parentEval, ctx, spec && spec.args);
        }, "childBypass", function(tr) {
            if (!pnid || !ctx || !ctx._policyTrace) return;
            if (!ctx._policyTrace[pnid]) return;
            if (!ctx._policyTrace[pnid].childBypass) {
                ctx._policyTrace[pnid].childBypass = { kind: "childBypass", evaluated: [], aggregate: null, final: null };
            }
            ctx._policyTrace[pnid].childBypass.evaluated.push({
                name: tr.name, priority: tr.priority || 0, enabled: true,
                args: tr.args,
                returned: tr.returned,
                effect: tr.effect || "combined",
                reasons: tr.returned && tr.returned.reasons ? tr.returned.reasons.slice() : []
            });
        }).value;
    }

    // COMPATIBILITY: old group-options config reader. Used when no primitive
    // expand/retain/takeover policies are configured on the node.
    // Fields like committedTokenPrefersGroup, showAllChildrenOnParentMatch,
    // flattenAllChildrenOnParentMatch, maxNestedChildren, etc. should be
    // replaced by per-kind primitive profiles.
    function groupDisplayPolicy(ev) {
        var flattenPolicy = ev.node.behavior && ev.node.behavior.flattenPolicy || {};
        var groupPolicy = flattenPolicy.groupDisplay || {};
        if (flattenPolicy.modeHint === "group-mode-inhibit")
            return null;
        return Object.assign({ enabled: true, parentWinsMargin: 0.08, childWinsMargin: 0.03, childDominatesMargin: 0.18, maxFlattenedChildren: 3, minChildScore: 0.25, showGroupHeaderInFilteredMode: true, committedTokenPrefersGroup: true, committedTokenMinParentScore: 0.25, showAllChildrenOnParentMatch: false, parentMatchMinScore: 0.25 }, groupPolicy);
    }

    // COMPATIBILITY: own-score computation used by the old group logic below.
    // Primitive nodes use the standard Evaluate scoring instead.
    function groupDominanceOwnScore(ev, ctx) {
        var primary = (ev.evidence || []).filter(function(e) {
            if (e.nodeId !== ev.node.id) return false;
            var group = Evidence.evidenceFieldGroup(e.field);
            return group === "primary-text" || group === "path-text" || group === "semantic-text";
        });
        if (!primary.length)
            return ev.ownScore;
        var score = 0;
        var overlaid = Evidence.overlayEvidence(primary, ctx.query);
        for (var i = 0; i < overlaid.length; i += 1)
            score = 1 - (1 - score) * (1 - Tokenize.clamp(overlaid[i].effective));
        return Tokenize.clamp(Math.min(score, ev.ownScore));
    }

    function riskLevelForNode(node) {
        if (!node) return "none";
        if (node.risk && node.risk.level) return node.risk.level;
        if (node.dangerous) return "state-change";
        return "none";
    }

    function activationModeForNode(node) {
        if (!node) return "normal";
        if (node.risk && node.risk.activation) return node.risk.activation;
        if (node.dangerous) {
            var label = String(node.label || "").toLowerCase();
            if (label.indexOf("logout") >= 0 || label.indexOf("shutdown") >= 0 || label.indexOf("reboot") >= 0 || label.indexOf("hibernate") >= 0)
                return "confirm-and-explicit-prefix";
            return "confirm";
        }
        return "normal";
    }

    function requiresConfirm(activation) {
        return activation === "confirm" || activation === "confirm-and-explicit-prefix" || activation === "terminal-confirm-or-explicit-prefix";
    }

    function requiresExplicitPrefix(node, activation) {
        return activation === "explicit-prefix-only" || activation === "confirm-and-explicit-prefix" || activation === "terminal-confirm-or-explicit-prefix";
    }

    function enrichWithRisk(policy, riskLevel, activation) {
        policy.risk = { level: riskLevel, activation: activation };
        policy.requiresConfirm = requiresConfirm(activation);
        policy.requiresExplicitPrefix = requiresExplicitPrefix(null, activation);
        return policy;
    }

    function findBestChild(ev, ctx) {
        var children = ev.children || [];
        var best = null;
        for (var i = 0; i < children.length; i += 1) {
            if (children[i].visible && (!best || children[i].score > best.score)) best = children[i];
        }
        return best;
    }

    function decidePresentation(ev, ctx) {
        if (!ev || !ev.node) return { mode: "normal", showParent: true };
        var node = ev.node;
        var riskLevel = riskLevelForNode(node);
        var activation = activationModeForNode(node);
        var chainNames = ["preset-presentation", "switch-presentation", "default-presentation"];
        var chainResult = PolicyChain.run(chainNames, function(name, spec) {
            var policy = PolicyChain.lookupPolicy(JsRegistry.presentation, spec);
            if (!policy) return null;
            return policy.apply(ev, ctx, spec && spec.args);
        }, "presentation");
        var decision = chainResult.value || { mode: "normal", showParent: true, children: ev.children || [] };
        return enrichWithRisk(decision, riskLevel, activation);
    }

    function decideByPreset(ev, ctx, preset) {
        var flattenPolicy = preset.flattenPolicy || {};
        var groupDisplay = flattenPolicy.groupDisplay || {};
        var showParent = preset.showParent !== false;
        if (preset.filterable && ev.ownVisible) {
            var childScore = groupDominanceOwnScore(ev, ctx);
            var visibleChildren = ev.children.filter(function(c) {
                return childPassesVisible(c, ev, ctx);
            }).sort(Evaluate.compareEvaluated);
            if (visibleChildren.length > 0) {
                var dominantChildren = visibleChildren.filter(function(c) { return childDominates(c, ev, ctx); });
                if (dominantChildren.length === 1)
                    return { mode: "flatten-children", showParent: false, children: dominantChildren };
                if (dominantChildren.length > 1)
                    return { mode: "nested-group", showParent: true, suppressParentActions: true, children: dominantChildren };
            }
            if (ctx.query.lastTokenEmpty && ev.ownScore >= (groupDisplay.minChildScore || 0.25)) {
                var browseChildren = visibleChildren.slice(0, groupDisplay.maxFlattenedChildren || 5);
                if (browseChildren.length > 0)
                    return { mode: "nested-group", showParent: showParent, children: browseChildren };
            }
            if (groupDisplay.showAllChildrenOnParentMatch && ev.ownScore >= (groupDisplay.parentMatchMinScore || 0.25)) {
                var allChildren = ev.children.filter(function(c) {
                    return c.allowed !== false && c.node.kind !== "backend";
                }).slice(0, groupDisplay.maxFlattenedChildren || 8);
                if (allChildren.length > 0)
                    return { mode: "nested-group", showParent: true, includeAllChildren: true, children: allChildren };
            }
            if (visibleChildren.length > 0)
                return { mode: "nested-group", showParent: showParent, children: visibleChildren };
            if (ev.ownVisible) return { mode: "group", showParent: showParent, children: [] };
            return { mode: "group", showParent: false, children: [] };
        }
        var bestChild = findBestChild(ev, ctx);
        if (bestChild && childDominates(bestChild, ev, ctx))
            return { mode: "flatten-children", showParent: false, children: [bestChild] };
        var visibleChildren = ev.children.filter(function(c) { return childPassesVisible(c, ev, ctx); }).sort(Evaluate.compareEvaluated);
        if (visibleChildren.length > 0)
            return { mode: "nested-group", showParent: showParent, children: visibleChildren };
        return { mode: "group", showParent: showParent, children: [] };
    }

    function decideSwitchPresentation(ev, ctx) {
        if (!ev.children || ev.children.length === 0) return { mode: "group", showParent: true, children: [] };
        if (ctx.query.lastTokenEmpty) {
            var browsePolicy = groupDisplayPolicy(ev) || {};
            var browseMaxChildren = browsePolicy.maxNestedChildren || browsePolicy.maxFlattenedChildren || 8;
            var browseChildren = ev.children.slice(0, browseMaxChildren);
            if (browseChildren.length > 0)
                return { mode: "nested-group", showParent: true, includeAllChildren: true, children: browseChildren };
            return { mode: "group", showParent: true, children: [] };
        }
        var policy = groupDisplayPolicy(ev) || {};
        var maxChildren = policy.maxNestedChildren || policy.maxFlattenedChildren || 8;
        var parentCovered = Evidence.coveredTokenIndexes(ev.evidence || [], ctx.query);
        var parentCoveredCount = Object.keys(parentCovered).length;
        if (parentCoveredCount >= ctx.query.tokens.length)
            return { mode: "group", showParent: true, children: [] };
        if (parentCoveredCount > 0) {
            var matching = [];
            for (var ci = 0; ci < ev.children.length; ci += 1) {
                var c = ev.children[ci];
                if (!c || !c.node) continue;
                var hl = Tokenize.normalizeText(String(c.node.label || "") + " " + (c.node.aliases || []).join(" "));
                for (var tj = 0; tj < ctx.query.tokens.length; tj += 1) {
                    if (parentCovered[tj]) continue;
                    var tn = Tokenize.normalizeText(ctx.query.tokens[tj].raw);
                    if (hl.indexOf(tn) === 0 || hl === tn) { matching.push(c); break; }
                }
            }
            if (matching.length > 0) {
                matching.sort(Evaluate.compareEvaluated);
                var taken = matching.slice(0, maxChildren);
                if (taken.length === 1)
                    return { mode: "flatten-children", showParent: false, children: taken };
                return { mode: "nested-group", showParent: true, suppressParentActions: true, includeAllChildren: true, children: taken };
            }
            return { mode: "group", showParent: true, children: [] };
        }
        var strongChildren = ev.children.filter(function(c) { return c.visible && childHasExactPrimaryMatch(c); }).sort(Evaluate.compareEvaluated).slice(0, maxChildren);
        if (strongChildren.length === 1)
            return { mode: "flatten-children", showParent: false, children: strongChildren };
        if (strongChildren.length > 0)
            return { mode: "nested-group", showParent: true, suppressParentActions: true, includeAllChildren: true, children: strongChildren };
        return { mode: "group", showParent: true, children: [] };
    }

    function childHasExactPrimaryMatch(childEval) {
        var evidence = childEval && childEval.ownEvidence || [];
        for (var i = 0; i < evidence.length; i += 1) {
            var e = evidence[i] || {};
            var group = Evidence.evidenceFieldGroup(e.field);
            var kind = String(e.kind || e.exactness || e.strategy || "");
            if (group === "primary-text" && kind.indexOf("exact") >= 0)
                return true;
        }
        return false;
    }

    function childCoversAdditionalToken(childEval, parentEval, ctx) {
        var parentCov = Evidence.coveredTokenIndexes(parentEval.evidence || [], ctx.query);
        var childCov = Evidence.coveredTokenIndexes(childEval.evidence || [], ctx.query);
        for (var key in childCov) {
            if (!(key in parentCov))
                return true;
        }
        return false;
    }

    function presentationRowHint(ev, ctx) {
        var decision = decidePresentation(ev, ctx);
        var node = ev.node;
        var riskLevel = riskLevelForNode(node);
        var activation = activationModeForNode(node);
        var hints = {};
        if (requiresConfirm(activation)) hints.confirmRequired = true;
        if (requiresExplicitPrefix(node, activation)) hints.explicitPrefixRequired = true;
        if (riskLevel !== "none") hints.riskLevel = riskLevel;
        var presentationId = (node.behavior && node.behavior.presentation) || node.presentation || "";
        return {
            presentation: presentationId || node.kind,
            flattenDecision: decision,
            risk: { level: riskLevel, activation: activation },
            hints: hints
        };
    }
}
