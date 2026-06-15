pragma ComponentBehavior: Bound

import QtQuick
import QtQml
import QtQml.Models

QtObject {
    id: root

    property ListModel model: ListModel {
        id: visualModel
    }
    property int animationMode: TransitionPolicy.Mode.Full
    property int recentlyRemovedTtl: 400
    property bool debugEnabled: false
    property int snapshotSerial: 0
    property var lastOperations: []
    property var _recentlyRemovedKeys: ({})
    property bool hasActiveItems: false
    property var _lastSnapshotTime: null
    property string _lastContextKey: ""
    property string _lastInputText: ""

    property TransitionPolicy policy: TransitionPolicy {
        id: transitionPolicy
    }

    property Timer _enteringSettleTimer: Timer {
        interval: transitionPolicy.settleDelay(root.animationMode)
        repeat: false
        onTriggered: root.settleEnteringRows()
    }

    property Timer _removedKeyCleanupTimer: Timer {
        interval: root.recentlyRemovedTtl
        repeat: false
        onTriggered: root.pruneRecentlyRemovedKeys()
    }

    property Timer _leavingRemovalTimer: Timer {
        interval: transitionPolicy.removalDelay(root.animationMode)
        repeat: false
        onTriggered: root.removeSettledLeavingRows()
    }

    signal snapshotApplied()

    function applySnapshot(items, context) {
        const rows = normaliseItems(items || []);
        root.snapshotSerial += 1;
        root.lastOperations = [];

        const ctx = context || {};
        const mode = transitionPolicy.modeForSnapshot({
            inputText: ctx.inputText || "",
            previousInputText: root._lastInputText,
            contextKey: ctx.contextKey || "",
            previousContextKey: root._lastContextKey,
            reason: ctx.reason || "",
            timeSinceLastSnapshot: root.timeSinceLastSnapshot(),
            snapshotSerial: root.snapshotSerial,
            activeItemCount: rows.length,
            previousItemCount: visualModel.count
        });

        root.animationMode = mode;
        root._lastInputText = ctx.inputText || "";
        root._lastContextKey = ctx.contextKey || "";
        root._lastSnapshotTime = Date.now();

        updateSurvivors(rows);
        insertNewRows(rows);
        moveRowsToTargetOrder(rows);
        removeMissingRows(rows);
        scheduleEnteringSettle();
        recomputeHasActiveItems();
        logSnapshot(rows);
        snapshotApplied();
    }

    function resetTransientState() {
        root._lastInputText = "";
        root._lastContextKey = "";
        root._recentlyRemovedKeys = ({});
        root._lastSnapshotTime = null;
        root.animationMode = TransitionPolicy.Mode.None;
    }

    function resetModel() {
        for (let i = visualModel.count - 1; i >= 0; i -= 1)
            visualModel.remove(i);
        root.hasActiveItems = false;
        root.resetTransientState();
    }

    function updateSurvivors(rows) {
        for (let targetIndex = 0; targetIndex < rows.length; targetIndex += 1) {
            const row = rows[targetIndex];
            const currentIndex = indexOfKey(row.key);

            if (currentIndex === -1)
                continue;

            if (currentIndex !== targetIndex || visualModel.get(currentIndex).phase !== "live")
                recordOperation("update", { key: row.key, from: currentIndex, to: targetIndex });
            visualModel.setProperty(currentIndex, "payload", row.payload);
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

            const phase = root.animationMode === TransitionPolicy.Mode.None || isRecentlyRemoved(row.key)
                ? "live"
                : "entering";
            recordOperation("insert", { key: row.key, to: targetIndex, phase: phase });
            visualModel.insert(Math.min(targetIndex, visualModel.count), {
                key: row.key,
                payload: row.payload,
                rank: targetIndex,
                zValue: zValueForRank(targetIndex),
                phase: phase,
                animationRole: row.animationRole || ""
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

    function normaliseItems(items) {
        const rows = [];
        const seen = ({});

        for (let i = 0; i < items.length; i += 1) {
            const item = items[i];
            const key = keyForItem(item);

            if (!key) {
                console.warn("[TransitionListCoordinator] item missing stable key at index", i);
                continue;
            }

            if (seen[key]) {
                console.warn("[TransitionListCoordinator] duplicate key:", key);
                continue;
            }

            seen[key] = true;
            rows.push({
                key: key,
                payload: item.payload !== undefined ? item.payload : item,
                rank: i,
                animationRole: item.animationRole || ""
            });
        }

        return rows;
    }

    function keyForItem(item) {
        if (!item)
            return "";
        if (item.key)
            return String(item.key);
        if (item.id)
            return String(item.id);
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

    function timeSinceLastSnapshot() {
        if (!root._lastSnapshotTime)
            return 9999;
        return Date.now() - root._lastSnapshotTime;
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

        const delay = transitionPolicy.settleDelay(root.animationMode);
        if (delay <= 0) {
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
            console.warn("[TransitionListCoordinator]", JSON.stringify(operation));
    }

    function logSnapshot(rows) {
        if (!root.debugEnabled)
            return;
        console.warn("[TransitionListCoordinator] snapshot", root.snapshotSerial, "mode", root.animationMode, "input", rows.length, "model", visualModel.count);
    }

    function debugState(extra) {
        const rows = [];
        for (let i = 0; i < visualModel.count; i += 1) {
            const row = visualModel.get(i);
            rows.push({
                index: i,
                key: row.key || "",
                rank: row.rank,
                zValue: row.zValue,
                phase: row.phase || "",
                animationRole: row.animationRole || ""
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
