import QtQml

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

    function removeStreamItem(id) {
        if (!id || !root.streamItemsById[id])
            return;
        var byId = Object.assign({}, root.streamItemsById);
        delete byId[id];
        root.streamItemsById = byId;
        root.streamOrder = root.streamOrder.filter(function(itemId) { return itemId !== id; });
    }

    function applyStreamUpdate(update) {
        if (!update)
            return;
        if (Array.isArray(update)) {
            root.resetStream(update);
            return;
        }

        const op = update.op || update.type || "upsert";
        if (op === "reset")
            root.resetStream(update.items || update.results || []);
        else if (op === "remove")
            root.removeStreamItem(update.id || streamItemId(update.item));
        else if (op === "clear")
            root.resetStream([]);
        else if (update.items)
            root.addStreamItems(update.items);
        else
            root.upsertStreamItem(update.item || update);
    }

    function streamSnapshot() {
        return root.compositeResults;
    }

    function streamItemId(item) {
        return item && (item.id || item.key || (item.metadata && item.metadata.path) || item.title) || "";
    }

    function backendRoot(children) {
        return root.backendRootDto(children);
    }
}
