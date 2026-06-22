import QtQml

QtObject {
    id: root

    property var controller: null
    property var navigationTargets: null
    property var expandedNodeIds: ({})

    function loadLazyChildren(key) {
        if (!root.controller || !root.navigationTargets) return;
        var treeRow = root.navigationTargets.findRowByKey(root.controller.results, key);
        if (!treeRow || !treeRow.lazy) return;
        var parentResult = root.navigationTargets.findParentResultByKey(root.controller.results, key);
        if (!parentResult) return;
        var sourceId = treeRow.source || parentResult.source || parentResult.backendId || "";
        var backend = null;
        for (var i = 0; i < (root.controller.backends || []).length; i += 1) {
            if (root.controller.backends[i] && root.controller.backendId(root.controller.backends[i]) === sourceId) {
                backend = root.controller.backends[i];
                break;
            }
        }
        if (!backend || typeof backend.scanDirectory !== "function") return;
        var path = (treeRow.meta && treeRow.meta.path) || "";
        if (!path && treeRow.id && treeRow.id.indexOf("file:") === 0)
            path = treeRow.id.slice(5);
        if (!path) return;
        backend.scanDirectory(path, function(children) {
            treeRow.children = children;
            treeRow.lazy = false;
            root.expandedNodeIds[treeRow.nodeId || treeRow.id] = true;
            if (root.controller && typeof root.controller.searchRequested === "function")
                root.controller.searchRequested(root.controller.query, root.controller.generation);
        });
    }
}
