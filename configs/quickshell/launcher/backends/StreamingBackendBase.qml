LauncherBackendBase {
    id: root

    property var streamItemsById: ({})
    property var streamOrder: []
    readonly property var compositeResults: streamOrder.map(function(id) { return streamItemsById[id]; }).filter(Boolean)

    function resetStream(items) {
        root.streamItemsById = {};
        root.streamOrder = [];
        root.addStreamItems(items || []);
    }

    function addStreamItems(items) {
        for (var i = 0; i < (items || []).length; i += 1)
            root.upsertStreamItem(items[i]);
    }

    function upsertStreamItem(item) {
        if (!item)
            return;
        var id = streamItemId(item);
        if (!id)
            return;
        var byId = Object.assign({}, root.streamItemsById);
        byId[id] = item;
        root.streamItemsById = byId;
        if (root.streamOrder.indexOf(id) < 0)
            root.streamOrder = root.streamOrder.concat([id]);
    }

    function applyStreamUpdate(update) {
        if (!update)
            return;
        if (Array.isArray(update)) {
            root.resetStream(update);
            return;
        }
        if (update.op === "clear")
            root.resetStream([]);
    }

    function streamItemId(item) {
        return item && (item.id || item.key || (item.metadata && item.metadata.path) || item.title) || "";
    }
}
