import QtQml
import "../logic/"

QtObject {
    id: root

    property var controller: null
    property var actionController: null
    property var controlHandler: null

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
                var confirmTarget = Object.assign({}, result, { risk: actions[i].risk || result.risk, dangerous: !!(actions[i].dangerous || result.dangerous) });
                var recipeResult = root.actionController
                    ? { success: root.actionController.activateWithConfirmation(confirmTarget, function() { return ActionRegistry.executeRecipe([["run-action", { action: actionId }]], result, root.controller).success; }) }
                    : ActionRegistry.executeRecipe([["run-action", { action: actionId }]], result, root.controller);
                if (root.controller && root.controller.debugEnabled)
                    console.warn("[Actions] activateResultAction matched action list", {
                        resultId: result.id || result.nodeId || "",
                        actionId: actionId || "",
                        activated: recipeResult.success,
                        payloadState: actions[i].payload ? actions[i].payload.state : undefined
                    });
                if (recipeResult.success && result.switchActions && root.controlHandler)
                    root.controlHandler.refreshSwitchResult(result, actions[i]);
                return recipeResult.success;
            }
        }

        if (result.switchActions && result.switchActions[actionId]) {
            var switchAction = result.switchActions[actionId];
            var switchConfirmTarget = Object.assign({}, result, { risk: switchAction.risk || result.risk, dangerous: !!(switchAction.dangerous || result.dangerous) });
            var switchResult = root.actionController
                ? { success: root.actionController.activateWithConfirmation(switchConfirmTarget, function() { return ActionRegistry.executeRecipe([["run-action", { action: actionId }]], result, root.controller).success; }) }
                : ActionRegistry.executeRecipe([["run-action", { action: actionId }]], result, root.controller);
            if (root.controller && root.controller.debugEnabled)
                console.warn("[Actions] activateResultAction matched switchActions", {
                    resultId: result.id || result.nodeId || "",
                    actionId: actionId || "",
                    activated: switchResult.success,
                    payloadState: result.switchActions[actionId].payload ? result.switchActions[actionId].payload.state : undefined
                });
            if (switchResult.success && root.controlHandler)
                root.controlHandler.refreshSwitchResult(result, result.switchActions[actionId]);
            return switchResult.success;
        }

        if (root.controller && root.controller.debugEnabled)
            console.warn("[Actions] activateResultAction no matching action", {
                resultId: result.id || result.nodeId || "",
                actionId: actionId || ""
            });
        return false;
    }
}
