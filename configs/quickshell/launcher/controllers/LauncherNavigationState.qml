import QtQuick
import QtQml
import QtQml.Models
import "../logic/DebugLogger.js" as DebugLogger

Item {
    id: root

    property var controller: null
    property var results: []
    property string resultsQuery: ""
    property int selectedIndex: 0
    property int selectedActionIndex: 0
    property var expandedNodeIds: ({})
    property var collapsedResultIndices: ({})
    property var lastQuery: null
    property var lastDirective: null
    property var lastEvaluatedRoot: null

    property var currentTreeView: null
    property string currentTreeKey: ""
    property int treeVisualRow: -1
    readonly property bool inTree: currentTreeView !== null && treeVisualRow >= 0
    property var resultTreeViews: ({})
    property var resultView: null
    property string activeNodeKey: ""

    function clearSearchOutputState() {
        lastQuery = null;
        lastDirective = null;
        lastEvaluatedRoot = null;
    }

    function clearResults() {
        results = [];
        resultsQuery = "";
        resetSelection();
    }

    function refreshResults() {
        results = results.slice();
    }

    function resetSelection() {
        selectedIndex = -1;
        selectedActionIndex = 0;
        resetTreeNavigation();
    }

    function queryIsEmptyForSelection() {
        if (lastQuery && lastQuery.isEmpty !== undefined)
            return !!lastQuery.isEmpty;
        return !controller || !controller.query || controller.query.trim().length === 0;
    }

    function hasActivation(row) {
        return !!(row && (row.actions && row.actions.length > 0 || row.executable || row.switchActions || row.control || (row.filterable && row.children && row.children.length > 0)));
    }

    function isSelectable(row) {
        return root.hasActivation(row) && (root.queryIsEmptyForSelection() || (row.ownScore || 0) > 0 || !!row.ownVisible);
    }

    function isRowSelectable(row) {
        return root.isSelectable(row);
    }

    function selectedResult() {
        return selectedIndex >= 0 ? results[selectedIndex] : null;
    }

    function rowKey(row) {
        return row ? row.id || row.nodeId || "" : "";
    }

    function setResults(newResults, sourceQuery) {
        if (controller && controller.debugEnabled)
            console.warn("[NAV] setResults: count=" + (newResults ? newResults.length : 0) + " query=" + sourceQuery + " prevCount=" + results.length);
        var sameQuery = (sourceQuery || "") === (resultsQuery || "");
        var previousActiveKey = sameQuery ? activeNodeKey : "";
        var previousCollapsedByKey = {};
        for (var previousIndex = 0; previousIndex < results.length; previousIndex += 1) {
            var previousKey = root.rowKey(results[previousIndex]);
            if (previousKey)
                previousCollapsedByKey[previousKey] = !!collapsedResultIndices[previousIndex];
            if (!previousActiveKey && sameQuery && previousIndex === selectedIndex)
                previousActiveKey = previousKey;
        }
        resultTreeViews = {};
        results = newResults || [];
        resultsQuery = sourceQuery || "";
        selectedActionIndex = 0;
        root.resetTreeNavigation();
        collapsedResultIndices = {};
        for (var i = 0; i < results.length; i += 1) {
            var key = root.rowKey(results[i]);
            if (results[i].alwaysExpanded !== false) {
            } else if (key && previousCollapsedByKey[key] !== undefined) {
                if (previousCollapsedByKey[key])
                    collapsedResultIndices[i] = true;
            } else {
                collapsedResultIndices[i] = true;
            }
            if (controller && controller.debugEnabled)
                console.warn("[NAV] setResults: result[" + i + "] key=" + key + " alwaysExpanded=" + results[i].alwaysExpanded + " collapsed=" + !!collapsedResultIndices[i] + " children=" + (results[i].children ? results[i].children.length : 0));
        }
        var targets = root.navigationTargets();
        var selectedTarget = previousActiveKey
            ? targets.find(function(target) { return target.key === previousActiveKey; })
            : null;
        if (controller && controller.debugEnabled)
            console.warn("[NAV] setResults: selecting target=" + (selectedTarget ? selectedTarget.key : (targets.length > 0 ? targets[0].key : "NONE")));
        root.applyNavigationTarget(selectedTarget || (targets.length > 0 ? targets[0] : null));
    }

    function registerResultTreeView(index, treeView) {
        if (index < 0 || !treeView) return;
        if (controller && controller.debugEnabled)
            console.warn("[NAV] registerResultTreeView index=" + index + " rows=" + treeView.rows + " selectedIndex=" + selectedIndex + " activeNodeKey=" + activeNodeKey);
        resultTreeViews[index] = treeView;
        if (index === selectedIndex && activeNodeKey)
            root.syncTreeSelection(index, activeNodeKey);
    }

    function moveSelection(delta) {
        var targets = root.navigationTargets();
        var nextTarget = root.stepTarget(targets, activeNodeKey, delta);
        if (!nextTarget) {
            if (controller && controller.debugEnabled)
                console.warn("[NAV] moveSelection: no targets, clearing");
            root.applyNavigationTarget(null);
            return;
        }
        if (controller && controller.debugEnabled)
            console.warn("[NAV] moveSelection delta=" + delta + " activeNodeKey=" + activeNodeKey + " targets=" + targets.length + " nextKey=" + nextTarget.key + " nextTitle=" + nextTarget.row.title + " nextDepth=" + nextTarget.depth + " nextParent=" + nextTarget.parentIndex);
        root.applyNavigationTarget(nextTarget);
    }

    function navigationTargets() {
        return flattenNavigationTargets(results, collapsedResultIndices, root.isRowSelectable);
    }

    function walkRows(rows, visitor) {
        function visit(row, parentIndex, depth, path) {
            if (!row) return false;
            var key = root.rowKey(row);
            var currentPath = path.concat([key]);
            if (visitor(row, parentIndex, depth, currentPath) === false)
                return false;
            var children = row.children || [];
            for (var i = 0; i < children.length; i += 1) {
                if (visit(children[i], parentIndex, depth + 1, currentPath) === false)
                    return false;
            }
            return true;
        }

        for (var i = 0; i < (rows || []).length; i += 1) {
            if (visit(rows[i], i, 0, []) === false)
                return;
        }
    }

    function findRowByKey(rows, key) {
        var found = null;
        root.walkRows(rows || [], function(row) {
            if (root.rowKey(row) === key) {
                found = row;
                return false;
            }
            return true;
        });
        return found;
    }

    function flattenNavigationTargets(rows, collapsedState, selectable) {
        var out = [];
        function visit(row, parentIndex, depth, path) {
            if (!row) return;
            var children = row.children || [];
            var key = root.rowKey(row);
            var currentPath = path.concat([key]);
            if (selectable(row))
                out.push({ key: key, row: row, parentIndex: parentIndex, depth: depth, treeDepth: depth, path: currentPath, isTreeChild: depth > 0 });
            if (collapsedState[parentIndex])
                return;
            for (var i = 0; i < children.length; i += 1)
                visit(children[i], parentIndex, depth + 1, currentPath);
        }
        for (var i = 0; i < (rows || []).length; i += 1)
            visit(rows[i], i, 0, []);
        if (controller && controller.debugEnabled)
            console.warn("[NAV] navigationTargets: results=" + results.length + " targets=" + out.length + " collapsed=" + Object.keys(collapsedResultIndices).join(",") + " targets=" + out.map(function(t) { return t.key + "(d=" + t.depth + " p=" + t.parentIndex + ")"; }).join(" | "));
        return out;
    }

    function stepTarget(targets, currentKey, delta) {
        if (!targets || targets.length === 0)
            return null;
        var current = targets.findIndex(function(target) { return target.key === currentKey; });
        if (current < 0)
            current = 0;
        var next = (current + delta + targets.length) % targets.length;
        return targets[next];
    }

    function resolveTreeViewAtIndex(index) {
        if (resultTreeViews[index]) {
            if (controller && controller.debugEnabled)
                console.warn("[NAV] resolveTreeView: cache hit index=" + index + " rows=" + resultTreeViews[index].rows);
            return resultTreeViews[index];
        }
        if (controller && controller.debugEnabled)
            console.warn("[NAV] resolveTreeView: cache miss index=" + index + " resultView=" + !!resultView);
        if (!resultView || index < 0)
            return null;
        var loader = resultView.itemAt(index);
        if (controller && controller.debugEnabled)
            console.warn("[NAV] resolveTreeView: loader=" + !!loader + " item=" + !!(loader && loader.item) + " treeView=" + !!(loader && loader.item && loader.item.treeView));
        if (loader && loader.item && loader.item.treeView) {
            resultTreeViews[index] = loader.item.treeView;
            if (controller && controller.debugEnabled)
                console.warn("[NAV] resolveTreeView: resolved from UI rows=" + loader.item.treeView.rows);
            return loader.item.treeView;
        }
        return null;
    }

    function applyNavigationTarget(target) {
        if (!target) {
            if (controller && controller.debugEnabled)
                console.warn("[NAV] applyNavigationTarget: null target, clearing");
            selectedIndex = -1;
            activeNodeKey = "";
            exitTree();
            return;
        }
        selectedIndex = target.parentIndex;
        selectedActionIndex = 0;
        activeNodeKey = target.key;
        if (target.isTreeChild || target.depth > 0 || target.treeDepth > 0) {
            if (controller && controller.debugEnabled)
                console.warn("[NAV] applyNav: depth=" + (target.depth || target.treeDepth) + " parentIndex=" + target.parentIndex + " key=" + target.key);
            currentTreeKey = target.key;
            root.syncTreeSelection(target.parentIndex, target.key);
        } else {
            if (controller && controller.debugEnabled)
                console.warn("[NAV] applyNav: depth=0 exiting tree");
            exitTree();
        }
    }

    function syncTreeSelection(parentIndex, key) {
        currentTreeView = resolveTreeViewAtIndex(parentIndex);
        currentTreeKey = key;
        if (controller && controller.debugEnabled)
            console.warn("[NAV] syncTreeSelection: currentTreeView=" + !!currentTreeView + " model=" + !!(currentTreeView && currentTreeView.model) + " viewRows=" + (currentTreeView ? currentTreeView.rows : "N/A"));
        treeVisualRow = currentTreeView ? root.findTreeVisualRow(currentTreeView, key) : -1;
        if (controller && controller.debugEnabled)
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

    function findTreeVisualRow(treeView, key) {
        if (!treeView || !treeView.model || !key) return -1;
        for (var row = 0; row < treeView.rows; row += 1) {
            var idx = treeView.index(row, 9);
            if (idx.valid && treeView.model.data(idx, "display") === key)
                return row;
        }
        return -1;
    }

    function resetTreeNavigation() {
        currentTreeView = null;
        currentTreeKey = "";
        treeVisualRow = -1;
        activeNodeKey = "";
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

    function toggleCollapseResultTree() {
        if (selectedIndex >= 0) {
            if (root.isInTree()) {
                return root.treeCollapseSelected();
            } else {
                var collapseResult = results[selectedIndex];
                if (!collapseResult || !collapseResult.children || collapseResult.children.length === 0)
                    return false;
                collapsedResultIndices[selectedIndex] = true;
                if (controller)
                    controller.collapseResultExpanded(selectedIndex);
            }
            return true;
        }
        return false;
    }

    function toggleExpandResultTree() {
        if (selectedIndex >= 0) {
            if (root.isInTree()) {
                return root.treeExpandSelected();
            } else {
                var expandResult = results[selectedIndex];
                if (!expandResult || !expandResult.children || expandResult.children.length === 0)
                    return false;
                delete collapsedResultIndices[selectedIndex];
                if (controller)
                    controller.expandResultExpanded(selectedIndex);
            }
            return true;
        }
        return false;
    }

    function exitTree() {
        if (currentTreeView && currentTreeView.selectionModel)
            currentTreeView.selectionModel.clearCurrentIndex();
        currentTreeView = null;
        currentTreeKey = "";
        treeVisualRow = -1;
    }

    function isInTree() {
        return inTree;
    }

    function moveInTree(delta) {
        if (!currentTreeView) return;
        var newRow = treeVisualRow + delta;
        if (newRow < 0) {
            exitTree();
            return;
        }
        if (newRow >= currentTreeView.rows) {
            exitTree();
            if (results.length > 0)
                selectedIndex = (selectedIndex + 1) % results.length;
            selectedActionIndex = 0;
            return;
        }
        treeVisualRow = newRow;
        var idx = currentTreeView.index(newRow, 0);
        if (!idx.valid) {
            exitTree();
            return;
        }
        currentTreeView.selectionModel.setCurrentIndex(idx, ItemSelectionModel.SelectCurrent);
    }

    function treeCollapseSelected() {
        if (!currentTreeView) {
            if (controller && controller.debugEnabled)
                DebugLogger.log("switch", "treeCollapseSelected without tree", {});
            return false;
        }
        if (treeVisualRow >= 0) {
            if (currentTreeView.isExpanded(treeVisualRow)) {
                if (typeof currentTreeView.collapseAnimated === "function")
                    currentTreeView.collapseAnimated(treeVisualRow);
                else
                    currentTreeView.collapse(treeVisualRow);
                if (controller && controller.debugEnabled)
                    DebugLogger.log("switch", "treeCollapseSelected collapsed current row", {
                        row: treeVisualRow,
                        key: currentTreeKey
                });
                return true;
            }
            var selectedTreeRow = root.findTreeRowData(currentTreeKey);
            if (selectedTreeRow && selectedTreeRow.switchActions) {
                if (controller && controller.debugEnabled)
                    DebugLogger.log("switch", "treeCollapseSelected switch leaf not handled", {
                        row: treeVisualRow,
                        key: currentTreeKey
                    });
                return false;
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
                if (controller && controller.debugEnabled)
                    DebugLogger.log("switch", "treeCollapseSelected collapsed parent row", {
                        row: treeVisualRow,
                        key: currentTreeKey
                    });
                return true;
            }
        }
        if (controller && controller.debugEnabled)
            DebugLogger.log("switch", "treeCollapseSelected not handled", {
                row: treeVisualRow,
                key: currentTreeKey
            });
        return false;
    }

    function treeExpandSelected() {
        if (!currentTreeView || treeVisualRow < 0) {
            if (controller && controller.debugEnabled)
                DebugLogger.log("switch", "treeExpandSelected without row", {
                    row: treeVisualRow,
                    key: currentTreeKey
                });
            return false;
        }
        var idx = currentTreeView.index(treeVisualRow, 0);
        var hasChildren = typeof currentTreeView.model.hasChildren === "function"
            ? currentTreeView.model.hasChildren(idx)
            : false;
        if (!hasChildren) {
            if (controller && controller.debugEnabled)
                DebugLogger.log("switch", "treeExpandSelected leaf not handled", {
                    row: treeVisualRow,
                    key: currentTreeKey
                });
            return false;
        }
        if (typeof currentTreeView.expandAnimated === "function")
            currentTreeView.expandAnimated(treeVisualRow);
        else
            currentTreeView.expand(treeVisualRow);
        if (controller && controller.debugEnabled)
            DebugLogger.log("switch", "treeExpandSelected expanded current row", {
                row: treeVisualRow,
                key: currentTreeKey
            });
        return true;
    }

    function treeToggleSelected() {
        if (!currentTreeView || treeVisualRow < 0) return;
        if (currentTreeView.isExpanded(treeVisualRow))
            treeCollapseSelected();
        else
            treeExpandSelected();
    }

    function findTreeRowData(key) {
        return key ? root.findRowByKey(results, key) : null;
    }

    function findInChildren(row, key) {
        return key ? root.findRowByKey(row ? [row] : [], key) : null;
    }

    function findParentResultByKey(key) {
        for (var i = 0; i < results.length; i += 1) {
            if (root.findRowByKey([results[i]], key))
                return results[i];
        }
        return null;
    }

    function loadLazyChildren(key) {
        var treeRow = root.findTreeRowData(key);
        if (!treeRow || !treeRow.lazy || !controller) return;
        var parentResult = root.findParentResultByKey(key);
        if (!parentResult) return;
        var sourceId = treeRow.source || parentResult.source || parentResult.backendId || "";
        var backend = null;
        for (var i = 0; i < (controller.backends || []).length; i += 1) {
            if (controller.backends[i] && controller.backendId(controller.backends[i]) === sourceId) {
                backend = controller.backends[i];
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
            controller.searchRequested(controller.query, controller.generation);
        });
    }
}
