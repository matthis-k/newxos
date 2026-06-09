pragma Singleton
import QtQuick
import Quickshell
import "../../logic/"
import "../../logic/CompositeSearchPolicyRegistry.js" as JsRegistry
import "PresentationPresets.qml"

Singleton {
    id: root
    readonly property var defaultChildVisible: ["visible-flag"]
    readonly property var defaultChildBypass: ["own-score-beats-parent", "score-dominates:0.03"]

    function childProfile(ev) {
        return (ev.node.evaluationProfile || {}).profile || {};
    }

    function childPassesVisible(childEval, parentEval, ctx) {
        var profile = childProfile(parentEval);
        var names = profile.childVisible || defaultChildVisible;
        return PolicyChain.run(names, function(name) {
            var policy = JsRegistry.childVisible.get(name);
            if (!policy) return false;
            return policy.apply(childEval, parentEval, ctx);
        }, "childVisible").value;
    }

    function childDominates(childEval, parentEval, ctx) {
        var profile = childProfile(parentEval);
        var names = profile.childBypass || defaultChildBypass;
        return PolicyChain.run(names, function(name) {
            var policy = JsRegistry.childBypass.get(name);
            if (!policy) return null;
            return policy.apply(childEval, parentEval, ctx);
        }, "childBypass").value;
    }

    function groupDisplayPolicy(ev) {
        var flattenPolicy = ev.node.behavior && ev.node.behavior.flattenPolicy || {};
        var groupPolicy = flattenPolicy.groupDisplay || {};
        if (flattenPolicy.modeHint === "group-mode-inhibit")
            return null;
        return Object.assign({ enabled: true, parentWinsMargin: 0.08, childWinsMargin: 0.03, childDominatesMargin: 0.18, maxFlattenedChildren: 3, minChildScore: 0.25, showGroupHeaderInFilteredMode: true, committedTokenPrefersGroup: true, committedTokenMinParentScore: 0.25, showAllChildrenOnParentMatch: false, parentMatchMinScore: 0.25 }, groupPolicy);
    }

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
        var chainResult = PolicyChain.run(chainNames, function(name) {
            var policy = JsRegistry.presentation.get(name);
            if (!policy) return null;
            return policy.apply(ev, ctx);
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
        var visibleChildren = ev.children.filter(function(c) { return childPassesVisible(c, ev, ctx); }).sort(Evaluate.compareEvaluated).slice(0, 8);
        if (visibleChildren.length > 0)
            return { mode: "nested-group", showParent: true, children: visibleChildren };
        return { mode: "group", showParent: true, children: [] };
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
