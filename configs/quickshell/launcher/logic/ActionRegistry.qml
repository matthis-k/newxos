pragma Singleton
import QtQml
import Quickshell
import Quickshell.Services.Pipewire
import qs.services
import "DebugLogger.js" as DebugLogger

Singleton {
    property var _executors: ({})
    property bool debugEnabled: false

    function register(name, executor) {
        _executors[name] = executor;
    }

    function execute(step, target, controller) {
        var name = step.name || "";
        var args = step.args || {};
        var executor = _executors[name];

        if (!executor) {
            if (debugEnabled)
                console.warn("[ActionRegistry] no executor for step: " + name);
            return { close: false, success: false };
        }

        try {
            var result = executor(target, args, controller);
            if (result === true || (result && result.close))
                return { close: true, success: true };
            if (result === false)
                return { close: false, success: false };
            if (result && typeof result === "object")
                return { close: !!result.close, success: result.success !== false };
            return { close: false, success: true };
        } catch (e) {
            if (debugEnabled)
                console.warn("[ActionRegistry] executor error for " + name + ": " + e);
            return { close: false, success: false };
        }
    }

    function executeRecipe(recipe, target, controller) {
        if (!recipe || !Array.isArray(recipe))
            return { close: false };

        for (var i = 0; i < recipe.length; i += 1) {
            var step = recipe[i];
            var result = execute(step, target, controller);
            if (result.close)
                return { close: true };
        }
        return { close: false };
    }

    function _resolveActionFromArgs(target, args) {
        if (args.action && args.action !== "default") {
            var actionId = args.action;

            if (target.switchActions && target.switchActions[actionId])
                return target.switchActions[actionId];

            var actions = target.actions || [];
            for (var i = 0; i < actions.length; i += 1) {
                if (actions[i].id === actionId)
                    return actions[i];
            }
            return { id: actionId };
        }

        if (args.prefer && Array.isArray(args.prefer)) {
            for (var pi = 0; pi < args.prefer.length; pi += 1) {
                var pid = args.prefer[pi];
                if (target.switchActions && target.switchActions[pid])
                    return target.switchActions[pid];
                var targetActions = target.actions || [];
                for (var ai = 0; ai < targetActions.length; ai += 1) {
                    if (targetActions[ai].id === pid)
                        return targetActions[ai];
                }
            }
        }

        var actions = target.actions || [];
        var defaultAction = actions.find(function(a) { return a.default; }) || actions[0] || null;
        return defaultAction;
    }

    function _runAction(target, action, controller) {
        if (!target || !action)
            return { close: false, success: false };

        if (action.intent) {
            var legacyResult = controller._legacyApplyIntent(target, action.intent);
            return { close: !!legacyResult, success: true };
        }

        var backend = null;
        for (var i = 0; i < (controller.backends || []).length; i += 1) {
            if (controller.backends[i] && controller.backendId(controller.backends[i]) === target.source) {
                backend = controller.backends[i];
                break;
            }
        }
        if (!backend)
            return { close: false, success: false };

        try {
            backend.activate(target, action);
            if (debugEnabled)
                DebugLogger.log("action", "run-action activated", {
                    targetId: target.id || target.nodeId || "",
                    actionId: action.id || ""
                });
            if (target.switchActions)
                controller.refreshSwitchResult(target, action);
            return { close: false, success: true };
        } catch (e) {
            if (debugEnabled)
                DebugLogger.log("action", "run-action failed: " + e, {});
            return { close: false, success: false };
        }
    }

    function _buildExecutors() {
        register("run-action", function(target, args, controller) {
            if (!target)
                return { close: false, success: false };

            var action = _resolveActionFromArgs(target, args);
            if (!action)
                return { close: false, success: false };

            return _runAction(target, action, controller);
        });

        register("close", function(target, args, controller) {
            return { close: true, success: true };
        });

        register("edit-query", function(target, args, controller) {
            var mode = args.mode || "replace";
            var text = "";

            if (args.from === "metadata.replaceQuery" && target.metadata && target.metadata.replaceQuery)
                text = target.metadata.replaceQuery;
            else if (args.text !== undefined)
                text = String(args.text);

            if (text && typeof controller.queryReplacementRequested === "function")
                controller.queryReplacementRequested(text);

            return { close: false, success: true };
        });

        register("adjust-control", function(target, args, controller) {
            if (!target || !target.control || target.control.kind !== "slider")
                return { close: false, success: false };

            var delta = Number(args.delta) || 0;
            var control = target.control;
            var step = control.step || 5;

            if (control.target === "brightness") {
                var aligned = controller._alignedControlValue(Brightness.percent, delta, step, control.from || 0, control.to || 100);
                Brightness.setPercent(aligned);
                return { close: false, success: true };
            }

            if (control.target === "pipewire") {
                for (const node of Pipewire.nodes.values || []) {
                    if (String(node.id) === String(control.nodeId) && node.audio) {
                        var current = Math.round((node.audio.volume || 0) * 100);
                        var next = controller._alignedControlValue(current, delta, step, control.from || 0, control.to || 150);
                        node.audio.volume = next / 100;
                        return { close: false, success: true };
                    }
                }
            }

            return { close: false, success: false };
        });

        register("noop", function(target, args, controller) {
            return { close: false, success: true };
        });
    }

    Component.onCompleted: _buildExecutors()
}
