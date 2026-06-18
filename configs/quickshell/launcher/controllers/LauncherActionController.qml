import QtQuick
import QtQml
import "../logic/"
import "../logic/DebugLogger.js" as DebugLogger

Item {
    id: root

    property var controller: null
    property var pendingConfirmId: null
    property int pendingConfirmTimeoutMs: 1600

    Timer {
        id: pendingConfirmTimer
        interval: root.pendingConfirmTimeoutMs
        onTriggered: root.pendingConfirmId = null
    }

    function activateSelected(shiftPressed) {
        if (controller.isInTree()) {
            if (controller.currentTreeKey)
                return root.activateTreeRowByKey(controller.currentTreeKey, null);
            return false;
        }
        var result = controller.selectedResult();
        if (!result)
            return false;

        if (result.risk && result.risk.activation) {
            if (result.id === root.pendingConfirmId) {
                root.pendingConfirmId = null;
                pendingConfirmTimer.stop();
                return root.executeRecipeSlot(result, shiftPressed ? "complete" : "activate");
            }
            if (root.requiresConfirm(result.risk.activation)) {
                root.pendingConfirmId = result.id;
                pendingConfirmTimer.restart();
                controller.resultsRefreshRequested();
                return false;
            }
        }

        return root.executeRecipeSlot(result, shiftPressed ? "complete" : "activate");
    }

    function requiresConfirm(activation) {
        return activation === "confirm" || activation === "confirm-and-explicit-prefix" || activation === "terminal-confirm-or-explicit-prefix";
    }

    function completeSelected() {
        var result = controller.selectedResult();
        if (!result)
            return false;
        return root.executeRecipeSlot(result, "complete");
    }

    function activateResult(result, action) {
        if (!result || !action)
            return false;

        if (result.metadata && result.metadata.replaceQuery) {
            controller.queryReplacementRequested(result.metadata.replaceQuery);
            return false;
        }

        var backend = null;
        for (var i = 0; i < (controller.backends || []).length; i += 1) {
            if (controller.backends[i] && controller.backendId(controller.backends[i]) === result.source) {
                backend = controller.backends[i];
                break;
            }
        }
        if (!backend)
            return false;

        try {
            backend.activate(result, action);
            if (controller.debugEnabled)
                DebugLogger.logExecute(result.id, action ? action.id : "", false, true);
            return true;
        } catch (error) {
            if (controller.debugEnabled)
                DebugLogger.logError("Activation failed for " + result.id, error);
            return false;
        }
    }

    function executeRecipeSlot(target, slotName) {
        var recipe = RecipeResolver.effectiveRecipe(target, slotName || "activate", {});
        var recipeResult = ActionRegistry.executeRecipe(recipe, target, controller);
        return !!recipeResult.close;
    }

    function applyIntent(result, intent) {
        if (!result || !intent)
            return false;
        switch (intent.type || "activate") {
        case "sequence": {
            var closeRequested = false;
            var steps = intent.steps || intent.actions || [];
            for (var si = 0; si < steps.length; si += 1) {
                if (root.applyIntent(result, steps[si]))
                    closeRequested = true;
            }
            return closeRequested;
        }
        case "close":
            return true;
        case "replace-query":
            controller.queryReplacementRequested(intent.text || "");
            return false;
        case "noop":
            return false;
        case "activate":
        default: {
            var actions = result && result.actions ? result.actions : [];
            var defaultAction = actions.find(function(a) { return a.default; }) || actions[0] || null;
            var selectedAction = intent.action || defaultAction;
            if (selectedAction && selectedAction.intent)
                return root.applyIntent(result, selectedAction.intent);
            root.activateResult(result, selectedAction);
            return false;
        }
        }
    }

    function activateResultAction(result, actionId) {
        if (!result) {
            if (controller.debugEnabled)
                DebugLogger.log("switch", "activateResultAction without result", { actionId: actionId || "" });
            return false;
        }
        var actions = result.actions || [];
        if (controller.debugEnabled)
            DebugLogger.log("switch", "activateResultAction", {
                resultId: result.id || result.nodeId || "",
                title: result.title || "",
                source: result.source || result.backendId || "",
                actionId: actionId || "",
                actionIds: actions.map(function(action) { return action ? action.id || "" : ""; }),
                hasSwitchActions: !!result.switchActions,
                switchActionIds: result.switchActions ? Object.keys(result.switchActions) : [],
                switchState: result.switchState
            });
        for (var i = 0; i < actions.length; i += 1) {
            if (actions[i] && actions[i].id === actionId) {
                var recipeResult = ActionRegistry.executeRecipe([["run-action", { action: actionId }]], result, controller);
                if (controller.debugEnabled)
                    DebugLogger.log("switch", "activateResultAction matched action list", {
                        resultId: result.id || result.nodeId || "",
                        actionId: actionId || "",
                        activated: recipeResult.success,
                        payloadState: actions[i].payload ? actions[i].payload.state : undefined
                    });
                if (recipeResult.success && result.switchActions)
                    root.refreshSwitchResult(result, actions[i]);
                return recipeResult.success;
            }
        }
        if (result.switchActions && result.switchActions[actionId]) {
            var switchResult = ActionRegistry.executeRecipe([["run-action", { action: actionId }]], result, controller);
            if (controller.debugEnabled)
                DebugLogger.log("switch", "activateResultAction matched switchActions", {
                    resultId: result.id || result.nodeId || "",
                    actionId: actionId || "",
                    activated: switchResult.success,
                    payloadState: result.switchActions[actionId].payload ? result.switchActions[actionId].payload.state : undefined
                });
            if (switchResult.success)
                root.refreshSwitchResult(result, result.switchActions[actionId]);
            return switchResult.success;
        }
        if (controller.debugEnabled)
            DebugLogger.log("switch", "activateResultAction no matching action", {
                resultId: result.id || result.nodeId || "",
                actionId: actionId || ""
            });
        return false;
    }

    function adjustSelectedValue(delta) {
        var result = root.selectedActionTarget();
        if (!result) {
            if (controller.debugEnabled)
                DebugLogger.log("switch", "adjustSelectedValue without target", { delta: delta });
            return false;
        }

        if (result.control) {
            var controlResult = ActionRegistry.executeRecipe([["adjust-control", { delta: delta }]], result, controller);
            if (controlResult.success)
                return true;
        }

        var preferredIds = delta < 0
            ? ["off", "decrease", "decrement", "left"]
            : ["on", "increase", "increment", "right"];
        if (controller.debugEnabled)
            DebugLogger.log("switch", "adjustSelectedValue", {
                delta: delta,
                preferredIds: preferredIds,
                inTree: controller.isInTree(),
                activeNodeKey: controller.activeNodeKey,
                targetId: result.id || result.nodeId || "",
                title: result.title || "",
                source: result.source || result.backendId || "",
                hasSwitchActions: !!result.switchActions,
                switchState: result.switchState
            });
        for (var i = 0; i < preferredIds.length; i += 1) {
            if (root.activateResultAction(result, preferredIds[i])) {
                if (controller.isInTree() && controller.currentTreeKey && result.switchActions && controller.selectedIndex >= 0) {
                    var treeRow = controller.findTreeRowData(controller.currentTreeKey);
                    if (treeRow)
                        treeRow.switchState = result.switchState;
                    controller.treeSwitchRefreshRequested(controller.selectedIndex);
                    if (controller.debugEnabled)
                        DebugLogger.log("switch", "adjustSelectedValue refreshed tree switch", {
                            rowKey: controller.currentTreeKey,
                            switchState: result.switchState
                        });
                }
                return true;
            }
        }
        if (controller.debugEnabled)
            DebugLogger.log("switch", "adjustSelectedValue no action activated", {
                delta: delta,
                targetId: result.id || result.nodeId || "",
                preferredIds: preferredIds
            });
        return false;
    }

    function toggleSelectedMute() {
        var result = root.selectedActionTarget();
        if (!result)
            return false;
        if (result.switchActions && (result.switchActions.toggle || result.switchActions.on || result.switchActions.off)) {
            var toggleResult = ActionRegistry.executeRecipe([["toggle"]], result, controller);
            return !!toggleResult.success;
        }
        return false;
    }

    function alignedControlValue(current, delta, step, from, to) {
        var base = delta < 0 ? Math.floor(current / step) * step : Math.ceil(current / step) * step;
        if (Math.abs(base - current) < 0.0001)
            base += delta * step;
        return Math.max(from, Math.min(to, base));
    }

    function refreshSwitchResult(result, action) {
        var payload = action && action.payload || {};
        var state = payload.state;
        var previous = result ? result.switchState : undefined;
        if (state === true || state === false) {
            result.switchState = state;
        } else if (state === null) {
            result.switchState = result.switchState === true ? false : true;
        }
        if (controller.debugEnabled)
            DebugLogger.log("switch", "refreshSwitchResult", {
                resultId: result ? result.id || result.nodeId || "" : "",
                actionId: action ? action.id || "" : "",
                payloadState: state,
                previousState: previous,
                nextState: result ? result.switchState : undefined
            });
        controller.resultsRefreshRequested();
        Qt.callLater(function() {
            controller.searchRequested(controller.query, controller.generation);
        });
    }

    function activateTreeRowByKey(key, actionId) {
        var row = controller.findTreeRowData(key);
        if (!row) return false;
        var parent = controller.findParentResultByKey(key);
        var target = Object.assign({}, row, {
            source: row.source || (parent ? parent.source || parent.backendId : ""),
            category: row.category || (parent ? parent.category : "")
        });
        if (actionId) {
            var activated = root.activateResultAction(target, actionId);
            if (activated && target.switchActions && controller.selectedIndex >= 0) {
                row.switchState = target.switchState;
                controller.treeSwitchRefreshRequested(controller.selectedIndex);
            }
            return activated;
        }
        return root.applyIntent(target, target.enter);
    }

    function treeActivateCurrent() {
        if (controller.currentTreeKey)
            return root.activateTreeRowByKey(controller.currentTreeKey, null);
        return false;
    }

    function runRecipe(recipe, target) {
        if (!recipe || !target)
            return { close: false };
        return ActionRegistry.executeRecipe(recipe, target, controller);
    }

    function runRecipeSlot(slotName) {
        var target = root.selectedActionTarget();
        if (!target)
            return { close: false };

        var recipe = root.effectiveRecipeForTarget(target, slotName);
        if (!recipe || recipe.length === 0)
            return { close: false };

        return root.runRecipe(recipe, target);
    }

    function runInteractionForKey(keyName) {
        var target = root.selectedActionTarget();
        if (!target)
            return { close: false, success: false };

        var interactions = root.effectiveInteractionsForTarget(target);
        if (!interactions || !interactions[keyName]) {
            if (controller.debugEnabled)
                console.warn("[Actions] no interaction for key: " + keyName);
            return { close: false, success: false };
        }

        return root.runRecipe(interactions[keyName].recipe, target);
    }

    function effectiveRecipeForTarget(target, slotName) {
        return RecipeResolver.effectiveRecipe(target, slotName, {
            parentInteractions: target.interactions || {}
        });
    }

    function effectiveInteractionsForTarget(target) {
        return RecipeResolver.effectiveInteractions(target, {
            parentInteractions: null
        });
    }

    function _legacyApplyIntent(result, intent) {
        return root.applyIntent(result, intent);
    }

    function _alignedControlValue(current, delta, step, from, to) {
        return root.alignedControlValue(current, delta, step, from, to);
    }

    function _handleActivationWithConfirm() {
        if (controller.isInTree()) {
            if (controller.currentTreeKey)
                return root.activateTreeRowByKey(controller.currentTreeKey, null);
            return { close: false };
        }

        var result = controller.selectedResult();
        if (!result)
            return { close: false };

        if (result.risk && result.risk.activation) {
            if (result.id === root.pendingConfirmId) {
                root.pendingConfirmId = null;
                pendingConfirmTimer.stop();
                var recipeResult = root.runRecipeSlot("activate");
                return { close: recipeResult.close, closeRequested: recipeResult.close };
            }
            if (root.requiresConfirm(result.risk.activation)) {
                root.pendingConfirmId = result.id;
                pendingConfirmTimer.restart();
                controller.resultsRefreshRequested();
                return { close: false, closeRequested: false };
            }
        }

        var recipeResult = root.runRecipeSlot("activate");
        return { close: recipeResult.close, closeRequested: recipeResult.close };
    }

    function selectedActionTarget() {
        if (controller.isInTree() && controller.currentTreeKey) {
            var treeRow = controller.findTreeRowData(controller.currentTreeKey);
            if (treeRow) {
                var parent = controller.results[controller.selectedIndex];
                return Object.assign({}, treeRow, {
                    source: treeRow.source || (parent ? parent.source || parent.backendId : ""),
                    category: treeRow.category || (parent ? parent.category : "")
                });
            }
        }
        return controller.selectedResult();
    }
}
