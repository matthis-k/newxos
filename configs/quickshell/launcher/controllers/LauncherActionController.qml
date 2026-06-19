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

    BackendActionExecutor {
        id: backendExecutor
        controller: root.controller
    }

    LegacyIntentExecutor {
        id: legacyIntentExecutor
        controller: root.controller
        actionController: root
    }

    ResultActionResolver {
        id: resultActionResolver
        controller: root.controller
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
        return backendExecutor.activateResult(result, action);
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
