import QtQuick
import QtQml

QtObject {
    id: root

    property var controller: null
    property var pendingConfirmId: null
    property int pendingConfirmTimeoutMs: 1600

    Timer {
        id: pendingConfirmTimer
        interval: root.pendingConfirmTimeoutMs
        onTriggered: root.pendingConfirmId = null
    }

    function requiresConfirm(activation) {
        return activation === "confirm" || activation === "confirm-and-explicit-prefix" || activation === "terminal-confirm-or-explicit-prefix";
    }

    function checkActivation(result, executeCallback) {
        if (!result)
            return { confirmed: true };

        if (result.risk && result.risk.activation) {
            if (result.id === root.pendingConfirmId) {
                root.pendingConfirmId = null;
                pendingConfirmTimer.stop();
                return { confirmed: true };
            }
            if (root.requiresConfirm(result.risk.activation)) {
                root.pendingConfirmId = result.id;
                pendingConfirmTimer.restart();
                if (root.controller)
                    root.controller.resultsRefreshRequested();
                return { confirmed: false, needsConfirm: true };
            }
        }

        return { confirmed: true };
    }

    function activateWithConfirm(result, slotName) {
        var check = root.checkActivation(result);
        if (!check.confirmed)
            return { close: false, closeRequested: false, needsConfirm: check.needsConfirm };

        if (!root.controller)
            return { close: false };

        var recipeResult = root.controller.runRecipeSlot(slotName || "activate");
        return { close: recipeResult.close, closeRequested: recipeResult.close };
    }
}
