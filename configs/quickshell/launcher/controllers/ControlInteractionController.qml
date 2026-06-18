import QtQml
import "../logic/DebugLogger.js" as DebugLogger
import "../logic/"

QtObject {
    id: root

    property var controller: null
    property var targetResolver: null

    function adjustSelectedValue(delta) {
        var result = root.targetResolver ? root.targetResolver.selectedActionTarget() : null;
        if (!result) {
            if (root.controller && root.controller.debugEnabled)
                console.warn("[Actions] adjustSelectedValue without target", { delta: delta });
            return false;
        }

        if (result.control) {
            var controlResult = ActionRegistry.executeRecipe([["adjust-control", { delta: delta }]], result, root.controller);
            if (controlResult.success)
                return true;
        }

        var preferredIds = delta < 0
            ? ["off", "decrease", "decrement", "left"]
            : ["on", "increase", "increment", "right"];
        if (root.controller && root.controller.debugEnabled)
            console.warn("[Actions] adjustSelectedValue", {
                delta: delta,
                preferredIds: preferredIds,
                inTree: root.controller ? root.controller.isInTree() : false,
                activeNodeKey: root.controller ? root.controller.activeNodeKey : "",
                targetId: result.id || result.nodeId || "",
                title: result.title || "",
                source: result.source || result.backendId || "",
                hasSwitchActions: !!result.switchActions,
                switchState: result.switchState
            });
        for (var i = 0; i < preferredIds.length; i += 1) {
            if (root.controller && root.controller.activateResultAction(result, preferredIds[i])) {
                if (root.controller && root.controller.isInTree() && root.controller.currentTreeKey && result.switchActions && root.controller.selectedIndex >= 0) {
                    var treeRow = root.controller.findTreeRowData(root.controller.currentTreeKey);
                    if (treeRow)
                        treeRow.switchState = result.switchState;
                    if (typeof root.controller.treeSwitchRefreshRequested === "function")
                        root.controller.treeSwitchRefreshRequested(root.controller.selectedIndex);
                    if (root.controller && root.controller.debugEnabled)
                        console.warn("[Actions] adjustSelectedValue refreshed tree switch", {
                            rowKey: root.controller.currentTreeKey,
                            switchState: result.switchState
                        });
                }
                return true;
            }
        }
        if (root.controller && root.controller.debugEnabled)
            console.warn("[Actions] adjustSelectedValue no action activated", {
                delta: delta,
                targetId: result.id || result.nodeId || "",
                preferredIds: preferredIds
            });
        return false;
    }

    function toggleSelectedMute() {
        var result = root.targetResolver ? root.targetResolver.selectedActionTarget() : null;
        if (!result)
            return false;
        if (result.switchActions && (result.switchActions.toggle || result.switchActions.on || result.switchActions.off)) {
            var toggleResult = ActionRegistry.executeRecipe([["toggle"]], result, root.controller);
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
        if (root.controller && root.controller.debugEnabled)
            console.warn("[Actions] refreshSwitchResult", {
                resultId: result ? result.id || result.nodeId || "" : "",
                actionId: action ? action.id || "" : "",
                payloadState: state,
                previousState: previous,
                nextState: result ? result.switchState : undefined
            });
        if (root.controller)
            root.controller.resultsRefreshRequested();
        Qt.callLater(function() {
            if (root.controller && typeof root.controller.searchRequested === "function")
                root.controller.searchRequested(root.controller.query, root.controller.generation);
        });
    }
}
