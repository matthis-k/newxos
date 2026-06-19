import QtQml
import "../logic/DebugLogger.js" as DebugLogger

QtObject {
    id: root

    property var controller: null

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
}
