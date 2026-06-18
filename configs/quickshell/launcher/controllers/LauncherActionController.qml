import QtQuick
import QtQml
import "../logic/"
import "../logic/DebugLogger.js" as DebugLogger

Item {
    id: root

    property var controller: null
    property var pendingConfirmId: null
    property int pendingConfirmTimeoutMs: 1600

    ActivationConfirmation {
        id: confirmHandler
        controller: root.controller
    }

    property alias pendingConfirmId: confirmHandler.pendingConfirmId
    property alias pendingConfirmTimeoutMs: confirmHandler.pendingConfirmTimeoutMs

    SelectedTargetResolver {
        id: targetResolver
        controller: root.controller
    }

    ControlInteractionController {
        id: controlHandler
        controller: root.controller
        targetResolver: targetResolver
    }

    function activateSelected(shiftPressed) {
        if (root.controller && root.controller.isInTree()) {
            if (root.controller.currentTreeKey)
                return targetResolver.activateTreeRowByKey(root.controller.currentTreeKey, null);
            return false;
        }

        var result = root.controller ? root.controller.selectedResult() : null;
        if (!result)
            return false;

        var check = confirmHandler.checkActivation(result);
        if (!check.confirmed)
            return false;

        return root.executeRecipeSlot(result, shiftPressed ? "complete" : "activate");
    }

    function requiresConfirm(activation) {
        return confirmHandler.requiresConfirm(activation);
    }

    function completeSelected() {
        var result = root.controller ? root.controller.selectedResult() : null;
        if (!result)
            return false;
        return root.executeRecipeSlot(result, "complete");
    }

    function activateResult(result, action) {
        if (!result || !action)
            return false;

        if (result.metadata && result.metadata.replaceQuery) {
            if (root.controller)
                root.controller.queryReplacementRequested(result.metadata.replaceQuery);
            return false;
        }

        var backend = null;
        for (var i = 0; i < (root.controller ? root.controller.backends || [] : []).length; i += 1) {
            if (root.controller.backends[i] && root.controller.backendId(root.controller.backends[i]) === result.source) {
                backend = root.controller.backends[i];
                break;
            }
        }
        if (!backend)
            return false;

        try {
            backend.activate(result, action);
            if (root.controller && root.controller.debugEnabled)
                DebugLogger.logExecute(result.id, action ? action.id : "", false, true);
            return true;
        } catch (error) {
            if (root.controller && root.controller.debugEnabled)
                DebugLogger.logError("Activation failed for " + result.id, error);
            return false;
        }
    }

    function executeRecipeSlot(target, slotName) {
        if (!target)
            return { close: false };
        var recipe = RecipeResolver.effectiveRecipe(target, slotName || "activate", {});
        var recipeResult = ActionRegistry.executeRecipe(recipe, target, root.controller);
        return { close: !!recipeResult.close, success: recipeResult.success };
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
            if (root.controller)
                root.controller.queryReplacementRequested(intent.text || "");
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
            if (root.controller && root.controller.debugEnabled)
                console.warn("[Actions] activateResultAction without result", { actionId: actionId || "" });
            return false;
        }
        var actions = result.actions || [];
        if (root.controller && root.controller.debugEnabled)
            console.warn("[Actions] activateResultAction", {
                resultId: result.id || result.nodeId || "",
                title: result.title || "",
                source: result.source || result.backendId || "",
                actionId: actionId || "",
                actionIds: actions.map(function(a) { return a ? a.id || "" : ""; }),
                hasSwitchActions: !!result.switchActions,
                switchActionIds: result.switchActions ? Object.keys(result.switchActions) : [],
                switchState: result.switchState
            });
        for (var i = 0; i < actions.length; i += 1) {
            if (actions[i] && actions[i].id === actionId) {
                var recipeResult = ActionRegistry.executeRecipe([["run-action", { action: actionId }]], result, root.controller);
                if (root.controller && root.controller.debugEnabled)
                    console.warn("[Actions] activateResultAction matched action list", {
                        resultId: result.id || result.nodeId || "",
                        actionId: actionId || "",
                        activated: recipeResult.success,
                        payloadState: actions[i].payload ? actions[i].payload.state : undefined
                    });
                if (recipeResult.success && result.switchActions)
                    controlHandler.refreshSwitchResult(result, actions[i]);
                return recipeResult.success;
            }
        }
        if (result.switchActions && result.switchActions[actionId]) {
            var switchResult = ActionRegistry.executeRecipe([["run-action", { action: actionId }]], result, root.controller);
            if (root.controller && root.controller.debugEnabled)
                console.warn("[Actions] activateResultAction matched switchActions", {
                    resultId: result.id || result.nodeId || "",
                    actionId: actionId || "",
                    activated: switchResult.success,
                    payloadState: result.switchActions[actionId].payload ? result.switchActions[actionId].payload.state : undefined
                });
            if (switchResult.success)
                controlHandler.refreshSwitchResult(result, result.switchActions[actionId]);
            return switchResult.success;
        }
        if (root.controller && root.controller.debugEnabled)
            console.warn("[Actions] activateResultAction no matching action", {
                resultId: result.id || result.nodeId || "",
                actionId: actionId || ""
            });
        return false;
    }

    function adjustSelectedValue(delta) {
        return controlHandler.adjustSelectedValue(delta);
    }

    function toggleSelectedMute() {
        return controlHandler.toggleSelectedMute();
    }

    function alignedControlValue(current, delta, step, from, to) {
        return controlHandler.alignedControlValue(current, delta, step, from, to);
    }

    function refreshSwitchResult(result, action) {
        controlHandler.refreshSwitchResult(result, action);
    }

    function activateTreeRowByKey(key, actionId) {
        return targetResolver.activateTreeRowByKey(key, actionId);
    }

    function treeActivateCurrent() {
        return targetResolver.treeActivateCurrent();
    }

    function runRecipe(recipe, target) {
        if (!recipe || !target)
            return { close: false };
        return ActionRegistry.executeRecipe(recipe, target, root.controller);
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
            if (root.controller && root.controller.debugEnabled)
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

    function _handleActivationWithConfirm() {
        if (root.controller && root.controller.isInTree()) {
            if (root.controller.currentTreeKey)
                return { close: targetResolver.activateTreeRowByKey(root.controller.currentTreeKey, null), closeRequested: false };
            return { close: false };
        }

        var result = root.controller ? root.controller.selectedResult() : null;
        if (!result)
            return { close: false };

        var check = confirmHandler.checkActivation(result);
        if (!check.confirmed)
            return { close: false, closeRequested: false, needsConfirm: check.needsConfirm };

        var recipeResult = root.runRecipeSlot("activate");
        return { close: recipeResult.close, closeRequested: recipeResult.close };
    }

    function selectedActionTarget() {
        return targetResolver.selectedActionTarget();
    }
}
