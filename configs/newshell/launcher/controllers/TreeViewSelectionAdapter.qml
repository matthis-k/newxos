import QtQuick
import QtQml
import QtQml.Models

QtObject {
    id: root

    property var controller: null
    property var resultTreeViews: ({})
    property var resultView: null
    property var currentTreeView: null
    property string currentTreeKey: ""
    property int treeVisualRow: -1

    readonly property bool inTree: currentTreeView !== null && treeVisualRow >= 0

    function registerTreeView(index, treeView) {
        if (index < 0 || !treeView) return;
        if (root.controller && root.controller.debugEnabled)
            console.warn("[NAV] registerResultTreeView index=" + index + " rows=" + treeView.rows + " currentTreeKey=" + currentTreeKey);
        resultTreeViews[index] = treeView;
        if (index === (root.controller ? root.controller.selectedIndex : -1) && currentTreeKey)
            root.syncSelection(index, currentTreeKey);
    }

    function resolveTreeViewAtIndex(index) {
        if (resultTreeViews[index]) {
            if (root.controller && root.controller.debugEnabled)
                console.warn("[NAV] resolveTreeView: cache hit index=" + index + " rows=" + resultTreeViews[index].rows);
            return resultTreeViews[index];
        }
        if (root.controller && root.controller.debugEnabled)
            console.warn("[NAV] resolveTreeView: cache miss index=" + index + " resultView=" + !!resultView);
        if (!resultView || index < 0)
            return null;
        var loader = resultView.itemAt(index);
        if (root.controller && root.controller.debugEnabled)
            console.warn("[NAV] resolveTreeView: loader=" + !!loader + " item=" + !!(loader && loader.item) + " treeView=" + !!(loader && loader.item && loader.item.treeView));
        if (loader && loader.item && loader.item.treeView) {
            resultTreeViews[index] = loader.item.treeView;
            if (root.controller && root.controller.debugEnabled)
                console.warn("[NAV] resolveTreeView: resolved from UI rows=" + loader.item.treeView.rows);
            return loader.item.treeView;
        }
        return null;
    }

    function syncSelection(parentIndex, key) {
        currentTreeView = resolveTreeViewAtIndex(parentIndex);
        currentTreeKey = key;
        if (root.controller && root.controller.debugEnabled)
            console.warn("[NAV] syncTreeSelection: currentTreeView=" + !!currentTreeView + " model=" + !!(currentTreeView && currentTreeView.model) + " viewRows=" + (currentTreeView ? currentTreeView.rows : "N/A"));
        treeVisualRow = currentTreeView ? root.findVisualRow(currentTreeView, key) : -1;
        if (root.controller && root.controller.debugEnabled)
            console.warn("[NAV] syncTreeSelection: treeVisualRow=" + treeVisualRow);
        if (!currentTreeView || treeVisualRow < 0)
            return false;
        var idx = currentTreeView.index(treeVisualRow, 0);
        if (idx.valid) {
            currentTreeView.selectionModel.setCurrentIndex(idx, ItemSelectionModel.SelectCurrent);
            return true;
        }
        return false;
    }

    function findVisualRow(treeView, key) {
        if (!treeView || !treeView.model || !key) return -1;
        for (var row = 0; row < treeView.rows; row += 1) {
            var idx = treeView.index(row, 9);
            if (idx.valid && treeView.model.data(idx, "display") === key)
                return row;
        }
        return -1;
    }

    function clear() {
        if (currentTreeView && currentTreeView.selectionModel)
            currentTreeView.selectionModel.clearCurrentIndex();
        currentTreeView = null;
        currentTreeKey = "";
        treeVisualRow = -1;
    }

    function enterTree(result, treeView) {
        if (!result || !treeView || treeView.rows <= 0) return false;
        currentTreeView = treeView;
        treeVisualRow = 0;
        var idx = treeView.index(0, 0);
        if (!idx.valid)
            return false;
        treeView.selectionModel.setCurrentIndex(idx, ItemSelectionModel.SelectCurrent);
        return true;
    }

    function moveInTree(delta) {
        if (!currentTreeView) return false;
        var newRow = treeVisualRow + delta;
        if (newRow < 0) {
            root.clear();
            return false;
        }
        if (newRow >= currentTreeView.rows) {
            root.clear();
            if (root.controller && root.controller.results && root.controller.results.length > 0)
                root.controller.selectedIndex = (root.controller.selectedIndex + 1) % root.controller.results.length;
            if (root.controller)
                root.controller.selectedActionIndex = 0;
            return false;
        }
        treeVisualRow = newRow;
        var idx = currentTreeView.index(newRow, 0);
        if (!idx.valid) {
            root.clear();
            return false;
        }
        currentTreeView.selectionModel.setCurrentIndex(idx, ItemSelectionModel.SelectCurrent);
        return true;
    }

    function treeCollapseSelected() {
        if (!currentTreeView) {
            if (root.controller && root.controller.debugEnabled)
                console.warn("[NAV] treeCollapseSelected without tree");
            return false;
        }
        if (treeVisualRow >= 0) {
            if (currentTreeView.isExpanded(treeVisualRow)) {
                if (typeof currentTreeView.collapseAnimated === "function")
                    currentTreeView.collapseAnimated(treeVisualRow);
                else
                    currentTreeView.collapse(treeVisualRow);
                if (root.controller && root.controller.debugEnabled)
                    console.warn("[NAV] treeCollapseSelected collapsed current row", { row: treeVisualRow, key: currentTreeKey });
                return true;
            }
            var idx = currentTreeView.index(treeVisualRow, 0);
            if (!idx.valid)
                return false;
            var parentIdx = currentTreeView.model.parent(idx);
            if (parentIdx.valid) {
                if (typeof currentTreeView.collapseAnimated === "function")
                    currentTreeView.collapseAnimated(parentIdx.row);
                else
                    currentTreeView.collapse(parentIdx.row);
                currentTreeView.selectionModel.setCurrentIndex(parentIdx, ItemSelectionModel.SelectCurrent);
                treeVisualRow = parentIdx.row;
                var keyIdx = currentTreeView.index(parentIdx.row, 9);
                currentTreeKey = keyIdx.valid ? currentTreeView.model.data(keyIdx, "display") : "";
                if (root.controller && root.controller.debugEnabled)
                    console.warn("[NAV] treeCollapseSelected collapsed parent row", { row: treeVisualRow, key: currentTreeKey });
                return true;
            }
        }
        if (root.controller && root.controller.debugEnabled)
            console.warn("[NAV] treeCollapseSelected not handled", { row: treeVisualRow, key: currentTreeKey });
        return false;
    }

    function treeExpandSelected() {
        if (!currentTreeView || treeVisualRow < 0) {
            if (root.controller && root.controller.debugEnabled)
                console.warn("[NAV] treeExpandSelected without row", { row: treeVisualRow, key: currentTreeKey });
            return false;
        }
        var idx = currentTreeView.index(treeVisualRow, 0);
        var hasChildren = typeof currentTreeView.model.hasChildren === "function"
            ? currentTreeView.model.hasChildren(idx)
            : false;
        if (!hasChildren) {
            if (root.controller && root.controller.debugEnabled)
                console.warn("[NAV] treeExpandSelected leaf not handled", { row: treeVisualRow, key: currentTreeKey });
            return false;
        }
        if (typeof currentTreeView.expandAnimated === "function")
            currentTreeView.expandAnimated(treeVisualRow);
        else
            currentTreeView.expand(treeVisualRow);
        if (root.controller && root.controller.debugEnabled)
            console.warn("[NAV] treeExpandSelected expanded current row", { row: treeVisualRow, key: currentTreeKey });
        return true;
    }

    function treeToggleSelected() {
        if (!currentTreeView || treeVisualRow < 0) return false;
        if (currentTreeView.isExpanded(treeVisualRow))
            return root.treeCollapseSelected();
        else
            return root.treeExpandSelected();
    }
}
