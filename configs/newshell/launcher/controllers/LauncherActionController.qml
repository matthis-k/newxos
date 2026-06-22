import QtQuick
import QtQml
import "../logic/"

Item {
    id: root

    property var controller: null

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

    LegacyIntentExecutor {
        id: legacyIntentExecutor
        controller: root.controller
        actionController: root
    }

    ResultActionResolver {
        id: resultActionResolver
        controller: root.controller
        actionController: root
        controlHandler: controlHandler
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

        return root.activateWithConfirmation(result, function() {
            return root.executeRecipeSlot(result, shiftPressed ? "complete" : "activate");
        });
    }

    function activateWithConfirmation(target, activationFn) {
        if (!target || typeof activationFn !== "function")
            return false;
        var check = confirmHandler.checkActivation(target);
        if (!check.confirmed)
            return false;

        if (root.controller)
            root.controller.confirmationSatisfied = true;
        try {
            return activationFn();
        } finally {
            if (root.controller)
                root.controller.confirmationSatisfied = false;
        }
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
            var editResult = ActionRegistry.executeRecipe([["edit-query", { from: "metadata.replaceQuery" }]], result, root.controller);
            return !!editResult.success;
        }
        var confirmationTarget = Object.assign({}, result, { risk: action.risk || result.risk, dangerous: !!(action.dangerous || result.dangerous) });
        return root.activateWithConfirmation(confirmationTarget, function() {
            var recipeResult = ActionRegistry.executeRecipe([["run-action", { action: action.id || "default" }]], result, root.controller);
            return !!recipeResult.success;
        });
    }

    function executeRecipeSlot(target, slotName) {
        if (!target)
            return { close: false };
        var recipe = RecipeResolver.effectiveRecipe(target, slotName || "activate", {});
        var recipeResult = ActionRegistry.executeRecipe(recipe, target, root.controller);
        return { close: !!recipeResult.close, success: recipeResult.success };
    }

    function applyIntent(result, intent) {
        return legacyIntentExecutor.applyIntent(result, intent);
    }

    function activateResultAction(result, actionId) {
        return resultActionResolver.activateResultAction(result, actionId);
    }

    function adjustSelectedValue(delta) {
        return controlHandler.adjustSelectedValue(delta);
    }

    function toggleSelectedMute() {
        return controlHandler.toggleSelectedMute();
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

    function activateSelectedFromInteraction(shiftPressed) {
        if (shiftPressed && root.controller && root.controller.navigation && root.controller.navigation.isInTree())
            return { close: root.controller.navigation.treeToggleSelected(), closeRequested: false };
        return root._handleActivationWithConfirm();
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

        var activationResult = root.activateWithConfirmation(result, function() {
            var recipeResult = root.runRecipeSlot("activate");
            return { close: recipeResult.close, closeRequested: recipeResult.close };
        });
        return activationResult || { close: false, closeRequested: false };
    }

    function selectedActionTarget() {
        return targetResolver.selectedActionTarget();
    }
}
