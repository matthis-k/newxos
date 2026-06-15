pragma ComponentBehavior: Bound

import QtQuick
import QtQml
import QtQml.Models

QtObject {
    id: root

    enum AnimationMode {
        None,
        Light,
        Full
    }

    property ListModel model: ListModel {
        id: visualModel
    }
    property int animationMode: VisualResultCoordinator.AnimationMode.Full
    property int recentlyRemovedTtl: 400
    property int leavingRemovalDelay: 180
    property bool debugEnabled: false
    property int snapshotSerial: 0
    property var lastOperations: []
    property string _lastQuery: ""
    property string _lastContextKey: ""
    property var _recentlyRemovedKeys: ({})
    property bool hasActiveItems: false

    property Timer _enteringSettleTimer: Timer {
        interval: root.enteringSettleDelay()
        repeat: false
        onTriggered: root.settleEnteringRows()
    }

    property Timer _removedKeyCleanupTimer: Timer {
        interval: root.recentlyRemovedTtl
        repeat: false
        onTriggered: root.pruneRecentlyRemovedKeys()
    }

    property Timer _leavingRemovalTimer: Timer {
        interval: root.leavingRemovalDelay
        repeat: false
        onTriggered: root.removeSettledLeavingRows()
    }

    signal snapshotApplied()

    function applySnapshot(results, mode) {
        const rows = normaliseResults(results || []);
        root.snapshotSerial += 1;
        root.lastOperations = [];
        root.animationMode = mode === undefined || mode === null
            ? VisualResultCoordinator.AnimationMode.Full
            : mode;

        updateSurvivors(rows);
        insertNewRows(rows);
        moveRowsToTargetOrder(rows);
        removeMissingRows(rows);
        scheduleEnteringSettle();
        recomputeHasActiveItems();
        logSnapshot(rows);
        snapshotApplied();
    }

    function animationModeForSnapshot(query, contextKey) {
        const nextQuery = query || "";
        const nextContextKey = contextKey || "";
        const previousQuery = root._lastQuery || "";
        const previousContextKey = root._lastContextKey || "";
        let mode = VisualResultCoordinator.AnimationMode.Full;

        if (nextQuery.trim().length === 0) {
            mode = visualModel.count > 0
                ? VisualResultCoordinator.AnimationMode.Light
                : VisualResultCoordinator.AnimationMode.None;
        } else if (previousContextKey !== "" && nextContextKey !== previousContextKey) {
            mode = VisualResultCoordinator.AnimationMode.Full;
        } else if (previousQuery.trim().length === 0) {
            mode = VisualResultCoordinator.AnimationMode.Full;
        } else if (previousQuery === nextQuery || isSingleCharacterEdit(previousQuery, nextQuery)) {
            mode = VisualResultCoordinator.AnimationMode.Light;
        }

        root._lastQuery = nextQuery;
        root._lastContextKey = nextContextKey;
        return mode;
    }

    function resetTransientState() {
        root._lastQuery = "";
        root._lastContextKey = "";
        root._recentlyRemovedKeys = ({});
        root.animationMode = VisualResultCoordinator.AnimationMode.None;
    }

    function resetModel() {
        for (let i = visualModel.count - 1; i >= 0; i -= 1)
            visualModel.remove(i);
        root.hasActiveItems = false;
        resetTransientState();
    }

    function updateSurvivors(rows) {
        for (let targetIndex = 0; targetIndex < rows.length; targetIndex += 1) {
            const row = rows[targetIndex];
            const currentIndex = indexOfKey(row.key);

            if (currentIndex === -1)
                continue;

            if (currentIndex !== targetIndex || visualModel.get(currentIndex).phase !== "live")
                recordOperation("update", { key: row.key, from: currentIndex, to: targetIndex });
            visualModel.setProperty(currentIndex, "result", row.result);
            visualModel.setProperty(currentIndex, "rank", targetIndex);
            visualModel.setProperty(currentIndex, "zValue", zValueForRank(targetIndex));
            visualModel.setProperty(currentIndex, "phase", "live");
        }
    }

    function insertNewRows(rows) {
        for (let targetIndex = 0; targetIndex < rows.length; targetIndex += 1) {
            const row = rows[targetIndex];

            if (indexOfKey(row.key) !== -1)
                continue;

            const phase = root.animationMode === VisualResultCoordinator.AnimationMode.None || isRecentlyRemoved(row.key)
                ? "live"
                : "entering";
            recordOperation("insert", { key: row.key, to: targetIndex, phase: phase });
            visualModel.insert(Math.min(targetIndex, visualModel.count), {
                key: row.key,
                result: row.result,
                rank: targetIndex,
                zValue: zValueForRank(targetIndex),
                phase: phase
            });
        }
    }

    function moveRowsToTargetOrder(rows) {
        for (let targetIndex = 0; targetIndex < rows.length; targetIndex += 1) {
            const row = rows[targetIndex];
            const currentIndex = indexOfKey(row.key);

            if (currentIndex === -1)
                continue;

            if (currentIndex !== targetIndex)
                visualModel.move(currentIndex, targetIndex, 1);
            if (currentIndex !== targetIndex)
                recordOperation("move", { key: row.key, from: currentIndex, to: targetIndex });

            visualModel.setProperty(targetIndex, "rank", targetIndex);
            visualModel.setProperty(targetIndex, "zValue", zValueForRank(targetIndex));
        }
    }

    function removeMissingRows(rows) {
        const targetKeys = ({});
        for (let i = 0; i < rows.length; i += 1)
            targetKeys[rows[i].key] = true;

        for (let i = visualModel.count - 1; i >= 0; i -= 1) {
            const key = visualModel.get(i).key;

            if (targetKeys[key])
                continue;

            if (visualModel.get(i).phase === "leaving")
                continue;

            rememberRecentlyRemoved(key);
            recordOperation("remove", { key: key, from: i });
            visualModel.setProperty(i, "phase", "leaving");
            visualModel.setProperty(i, "zValue", -1);
        }
        scheduleLeavingRemoval();
    }

    function normaliseResults(results) {
        const rows = [];
        const seen = ({});

        for (let i = 0; i < results.length; i += 1) {
            const result = results[i];
            const key = keyForResult(result);

            if (!key) {
                console.warn("Launcher result is missing a stable key at rank", i);
                continue;
            }

            if (seen[key]) {
                console.warn("Duplicate launcher result key:", key);
                continue;
            }

            seen[key] = true;
            rows.push({ key: key, result: result });
        }

        return rows;
    }

    function keyForResult(row) {
        if (!row)
            return "";
        if (row.key)
            return String(row.key);
        if (row.id)
            return String(row.id);
        if (row.nodeId)
            return String(row.nodeId);
        if (row.metadata && row.metadata.nodeId)
            return String(row.metadata.nodeId);
        return "";
    }

    function indexOfKey(key) {
        for (let i = 0; i < visualModel.count; i += 1) {
            if (visualModel.get(i).key === key)
                return i;
        }

        return -1;
    }

    function zValueForRank(rank) {
        return 10000 - rank;
    }

    function isSingleCharacterEdit(previousQuery, nextQuery) {
        if (Math.abs(previousQuery.length - nextQuery.length) !== 1)
            return false;
        return previousQuery.indexOf(nextQuery) === 0 || nextQuery.indexOf(previousQuery) === 0;
    }

    function enteringSettleDelay() {
        switch (root.animationMode) {
        case VisualResultCoordinator.AnimationMode.None:
            return 0;
        case VisualResultCoordinator.AnimationMode.Light:
            return 100;
        default:
            return 160;
        }
    }

    function scheduleEnteringSettle() {
        let hasEntering = false;
        for (let i = 0; i < visualModel.count; i += 1) {
            if (visualModel.get(i).phase === "entering") {
                hasEntering = true;
                break;
            }
        }

        if (!hasEntering)
            return;

        if (enteringSettleDelay() <= 0) {
            settleEnteringRows();
            return;
        }

        root._enteringSettleTimer.restart();
    }

    function settleEnteringRows() {
        for (let i = 0; i < visualModel.count; i += 1) {
            if (visualModel.get(i).phase === "entering")
                visualModel.setProperty(i, "phase", "live");
        }
    }

    function rememberRecentlyRemoved(key) {
        if (!key)
            return;
        const removed = Object.assign({}, root._recentlyRemovedKeys);
        removed[key] = Date.now();
        root._recentlyRemovedKeys = removed;
        root._removedKeyCleanupTimer.restart();
    }

    function isRecentlyRemoved(key) {
        const removedAt = root._recentlyRemovedKeys[key];
        return removedAt !== undefined && Date.now() - removedAt <= root.recentlyRemovedTtl;
    }

    function pruneRecentlyRemovedKeys() {
        const now = Date.now();
        const next = ({});
        for (const key in root._recentlyRemovedKeys) {
            if (now - root._recentlyRemovedKeys[key] <= root.recentlyRemovedTtl)
                next[key] = root._recentlyRemovedKeys[key];
        }
        root._recentlyRemovedKeys = next;
        if (Object.keys(next).length > 0)
            root._removedKeyCleanupTimer.restart();
    }

    function scheduleLeavingRemoval() {
        for (let i = 0; i < visualModel.count; i += 1) {
            if (visualModel.get(i).phase === "leaving") {
                root._leavingRemovalTimer.restart();
                return;
            }
        }
    }

    function removeSettledLeavingRows() {
        for (let i = visualModel.count - 1; i >= 0; i -= 1) {
            if (visualModel.get(i).phase === "leaving")
                visualModel.remove(i);
        }
        root.recomputeHasActiveItems();
    }

    function recomputeHasActiveItems() {
        for (let i = 0; i < visualModel.count; i += 1) {
            if (visualModel.get(i).phase !== "leaving") {
                root.hasActiveItems = true;
                return;
            }
        }
        root.hasActiveItems = false;
    }

    function recordOperation(type, details) {
        const operation = Object.assign({ type: type }, details || {});
        root.lastOperations = root.lastOperations.concat([operation]);
        if (root.debugEnabled)
            console.warn("[launcher-visual]", JSON.stringify(operation));
    }

    function logSnapshot(rows) {
        if (!root.debugEnabled)
            return;
        console.warn("[launcher-visual] snapshot", root.snapshotSerial, "mode", root.animationMode, "input", rows.length, "model", visualModel.count);
    }

    function debugState(extra) {
        const rows = [];
        for (let i = 0; i < visualModel.count; i += 1) {
            const row = visualModel.get(i);
            const result = row.result || {};
            rows.push({
                index: i,
                key: row.key || "",
                rank: row.rank,
                zValue: row.zValue,
                phase: row.phase || "",
                title: result.title || "",
                source: result.source || result.backendId || ""
            });
        }
        return {
            snapshotSerial: root.snapshotSerial,
            animationMode: root.animationMode,
            debugEnabled: root.debugEnabled,
            modelCount: visualModel.count,
            rows: rows,
            lastOperations: root.lastOperations,
            recentlyRemovedKeys: Object.keys(root._recentlyRemovedKeys),
            metrics: extra || {}
        };
    }
}
