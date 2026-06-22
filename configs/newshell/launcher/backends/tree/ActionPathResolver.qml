import QtQml

QtObject {
    id: root

    property var treeRootsProvider: null

    function originalNodeForPath(commandPath) {
        var nodes = root.treeRootsProvider ? root.treeRootsProvider() : [];
        var current = null;

        for (var i = 0; i < (commandPath || []).length; i += 1) {
            var wanted = commandPath[i];
            current = null;

            for (var ni = 0; ni < nodes.length; ni += 1) {
                var candidate = nodes[ni];
                if ((candidate.id || candidate.title) === wanted) {
                    current = candidate;
                    break;
                }
            }

            if (!current)
                return null;

            nodes = current.children || [];
        }

        return current;
    }

    function actionPayloadForPath(commandPath, actionId) {
        var node = root.originalNodeForPath(commandPath);
        if (!node)
            return null;

        var ownAction = node.defaultAction || node.action || null;
        if (ownAction && (!actionId || ownAction.actionId === actionId || ownAction.id === actionId))
            return ownAction;

        if (node.switchActions && node.switchActions[actionId])
            return node.switchActions[actionId];

        for (var i = 0; i < (node.children || []).length; i += 1) {
            var child = node.children[i];
            var childAction = child.defaultAction || child.action || null;
            if (childAction && (child.id === actionId || childAction.actionId === actionId || childAction.id === actionId))
                return childAction;
        }

        return ownAction;
    }
}
