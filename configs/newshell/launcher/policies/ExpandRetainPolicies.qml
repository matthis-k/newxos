import QtQml
import "../" as Launcher
import "../logic/"

QtObject {
    Component.onCompleted: {
        Launcher.PolicyRegistry.registerExpand("expand-when", function(ev, ctx, args) {
            var mode = (args && args.mode) || "own-match";
            var maxChildren = (args && args.maxChildren) || 8;
            var minScore = (args && args.minScore) || 0.1;
            if (!ev || !ev.children) return { expand: false, reason: "no children" };

            var visibleChildren = ev.children.filter(function(c) {
                return c.visible && c.score >= minScore;
            });

            var ownMatched = !!(ev.ownVisible || (ev.ownScore || 0) >= minScore);
            var expand = false;
            if (mode === "all") expand = true;
            else if (mode === "visible-children") expand = visibleChildren.length > 0;
            else expand = ownMatched;

            return {
                expand: expand,
                maxChildren: maxChildren,
                reason: "expand-when: mode " + mode + ", ownMatched " + ownMatched + ", " + visibleChildren.length + " visible children"
            };
        });

        Launcher.PolicyRegistry.registerExpand("expand-on-own-match", function(ev, ctx, args) {
            var maxChildren = (args && args.maxChildren) || 8;
            var minScore = (args && args.minScore) || 0.1;
            var ownMatched = !!(ev && (ev.ownVisible || (ev.ownScore || 0) >= minScore));
            return {
                expand: ownMatched,
                maxChildren: maxChildren,
                includeAllChildren: ownMatched,
                reason: ownMatched ? "expand-on-own-match: parent has own match" : "expand-on-own-match: parent has no own match"
            };
        });

        Launcher.PolicyRegistry.registerExpand("expand-on-trailing-space", function(ev, ctx, args) {
            var maxChildren = (args && args.maxChildren) || 8;
            var ownRequired = !(args && args.ownRequired === false);
            var ownMatched = !!(ev && (ev.ownVisible || (ev.ownScore || 0) > 0));
            var trailing = !!(ctx && ctx.query && ctx.query.lastTokenEmpty);
            var expand = trailing && (!ownRequired || ownMatched);
            return {
                expand: expand,
                maxChildren: maxChildren,
                includeAllChildren: expand,
                reason: expand ? "expand-on-trailing-space" : "expand-on-trailing-space: no trailing-space browse"
            };
        });

        Launcher.PolicyRegistry.registerExpand("expand-on-own-match-or-trailing-space", function(ev, ctx, args) {
            var maxChildren = (args && args.maxChildren) || 8;
            var minScore = (args && args.minScore) || 0.1;
            var ownMatched = !!(ev && (ev.ownVisible || (ev.ownScore || 0) >= minScore));
            var trailing = !!(ctx && ctx.query && ctx.query.lastTokenEmpty);
            var residual = (ev && ev.tokenFlow && ev.tokenFlow.passed) ? ev.tokenFlow.passed.length : 0;
            var expand = ownMatched || trailing;
            var browseAll = trailing && residual === 0;
            var filterByResidual = !trailing && residual > 0;
            return {
                expand: expand,
                maxChildren: maxChildren,
                includeAllChildren: browseAll,
                minScore: filterByResidual ? 0.02 : (browseAll ? 0 : 0.25),
                reason: expand
                    ? browseAll
                        ? "expand-on-own-match-or-trailing-space: trailing browse includes all children"
                        : filterByResidual
                        ? "expand-on-own-match-or-trailing-space: residual tokens filter children"
                        : "expand-on-own-match-or-trailing-space: own match expands children"
                    : "expand-on-own-match-or-trailing-space: not expanded"
            };
        });

        Launcher.PolicyRegistry.registerExpand("expand-on-explicit-parent-token", function(ev, ctx, args) {
            var maxChildren = (args && args.maxChildren) || 8;
            var minScore = (args && args.minScore) || 0.25;
            var expand = !!(ev && (ev.ownVisible || (ev.ownScore || 0) >= minScore));
            return {
                expand: expand,
                maxChildren: maxChildren,
                reason: expand ? "expand-on-explicit-parent-token" : "expand-on-explicit-parent-token: parent token absent"
            };
        });

        Launcher.PolicyRegistry.registerExpand("expand-on-child-match", function(ev, ctx, args) {
            var maxChildren = (args && args.maxChildren) || 8;
            var minScore = (args && args.minScore) || 0.1;
            var visibleChildren = (ev && ev.children || []).filter(function(c) {
                return c.visible && c.score >= minScore;
            });
            return {
                expand: visibleChildren.length > 0,
                maxChildren: maxChildren,
                reason: "expand-on-child-match: " + visibleChildren.length + " visible children"
            };
        });

        Launcher.PolicyRegistry.registerExpand("expand-all", function(ev, ctx, args) {
            var maxChildren = (args && args.maxChildren) || 24;
            return {
                expand: true,
                maxChildren: maxChildren,
                reason: "expand-all: all children visible"
            };
        });

        Launcher.PolicyRegistry.registerExpand("expand-none", function(ev, ctx, args) {
            return {
                expand: false,
                maxChildren: 0,
                reason: "expand-none: no children visible"
            };
        });

        Launcher.PolicyRegistry.registerRetainParent("retain-parent-when", function(ev, ctx, args) {
            var condition = (args && args.condition) || "has-own-score";
            var retainReason = "";

            switch (condition) {
            case "own-match":
            case "has-own-score":
                return {
                    retain: (ev.ownScore || 0) > 0,
                    reason: ev.ownScore > 0 ? "retain-parent-when: parent has own score" : "retain-parent-when: parent has no own score"
                };
            case "has-actions":
                var hasActions = (ev.node && ev.node.actionList && ev.node.actionList.length > 0) || (ev.node && ev.node.switchActions);
                return {
                    retain: !!hasActions,
                    reason: hasActions ? "retain-parent-when: parent has actions" : "retain-parent-when: parent has no actions"
                };
            case "switched":
                var isSwitch = !!(ev.node && ev.node.switchState !== undefined);
                return {
                    retain: isSwitch,
                    reason: isSwitch ? "retain-parent-when: parent is a switch" : "retain-parent-when: parent is not a switch"
                };
            case "has-risk":
                var hasRisk = (ev.node && (ev.node.risk || ev.node.dangerous));
                return {
                    retain: !!hasRisk,
                    reason: hasRisk ? "retain-parent-when: parent has risk context" : "retain-parent-when: parent has no risk"
                };
            default:
                return {
                    retain: true,
                    reason: "retain-parent-when: unknown condition '" + condition + "', retaining"
                };
            }
        });

        Launcher.PolicyRegistry.registerRetainParent("retain-always", function(ev, ctx, args) {
            return { retain: true, reason: "retain-always" };
        });

        Launcher.PolicyRegistry.registerRetainParent("retain-never", function(ev, ctx, args) {
            return { retain: false, reason: "retain-never" };
        });

        Launcher.PolicyRegistry.registerDefaultAction("default-action-owner", function(ev, ctx, args) {
            var ownerId = (args && args.ownerId) || (ev.node && ev.node.id) || "";
            var actionId = (args && args.actionId) || "";
            var reason = "default-action-owner: " + (args && args.reason ? args.reason : "policy declared");

            return {
                ownerId: ownerId,
                actionId: actionId,
                reason: reason
            };
        });

        Launcher.PolicyRegistry.registerDefaultAction("default-action-expand", function(ev, ctx, args) {
            return {
                ownerId: ev.node ? ev.node.id : "",
                actionId: "expand",
                reason: "default-action-expand: enter expands the group"
            };
        });
    }
}
