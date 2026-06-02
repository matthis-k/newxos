import QtQml

TreeBackendBase {
    id: root

    prewarmCompositeRootCache: false

    function rebuildModelTree() {
        root.invalidateCompositeRootCache();
    }
}
