import QtQml

QtObject {
    id: root

    property var controller: null
    property var actionController: null

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
        case "edit-query":
            if (root.controller)
                root.controller.queryReplacementRequested(intent.value || intent.text || "");
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
            if (root.actionController)
                root.actionController.activateResult(result, selectedAction);
            return false;
        }
        }
    }
}
