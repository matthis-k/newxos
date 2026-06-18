import QtQml

QtObject {
    id: root

    property var nodeFactory: null

    function originalNodeForPath(path, rootNode) {
        if (!path || path.length === 0 || !rootNode)
            return null;
        var current = rootNode;
        for (var i = 0; i < path.length; i++) {
            var segment = path[i];
            if (!current.children)
                return null;
            var found = false;
            for (var j = 0; j < current.children.length; j++) {
                var child = current.children[j];
                if (child.id === segment || child.title === segment) {
                    current = child;
                    found = true;
                    break;
                }
            }
            if (!found)
                return null;
        }
        return current;
    }

    function actionPayloadForPath(payload, rootNode) {
        if (!payload || !payload.actionId || !payload.path)
            return payload;
        var action = payload.actionId;
        var node = originalNodeForPath(payload.path, rootNode);
        if (!node)
            return payload;
        var targetAction = node.defaultAction || node.action || null;
        for (var i = 0; i < (node.children || []).length; i++) {
            var child = node.children[i];
            if (child.actionList && child.actionList.length > 0) {
                var leafAction = child.actionList[0];
                if (leafAction && leafAction.id === action) {
                    targetAction = leafAction.payload || leafAction;
                    if (targetAction.path)
                        targetAction.path = [node.id || node.title].concat(targetAction.path || []);
                    break;
                }
            }
        }
        return targetAction || payload;
    }
}
