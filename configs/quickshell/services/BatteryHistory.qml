pragma Singleton
import QtQml
import QtQuick
import QtCore
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

Singleton {
    id: root

    property UPowerDevice bat: UPower.displayDevice
    property real batteryPercent: 0
    property bool hasBattery: false

    // History buffer for battery graph (48 samples at 5min interval = 4 hours)
    // Each entry: {time: timestamp_ms, value: percent}
    property int batteryHistoryMaxSamples: 48
    property var batteryHistory: []
    property string _cachePath: StandardPaths.writableLocation(StandardPaths.CacheLocation) + "/battery-history.json"

    function _nowMs() {
        return Date.now();
    }

    function _fourHoursAgoMs() {
        return root._nowMs() - (4 * 60 * 60 * 1000);
    }

    function _filterToWindow(entries) {
        const cutoff = root._fourHoursAgoMs();
        return entries.filter(e => e.time >= cutoff);
    }

    function pushToHistory(value) {
        const entry = { time: root._nowMs(), value: value };
        batteryHistory.push(entry);
        const filtered = root._filterToWindow(batteryHistory);
        while (filtered.length > root.batteryHistoryMaxSamples)
            filtered.shift();
        batteryHistory = filtered;
        root._saveToFile();
    }

    function _saveToFile() {
        const json = JSON.stringify(batteryHistory);
        const dir = StandardPaths.writableLocation(StandardPaths.CacheLocation);
        saver.exec({
            command: ["sh", "-c", `mkdir -p "$1" && printf '%s' "$2" > "$1/battery-history.json"`, "save", dir, json]
        });
    }

    function _loadFromFile() {
        loader.exec({
            command: ["sh", "-c", `cat "${root._cachePath}" 2>/dev/null || echo '[]'`]
        });
    }

    function _applyLoaded(text) {
        try {
            const entries = JSON.parse(text || "[]");
            if (Array.isArray(entries)) {
                batteryHistory = root._filterToWindow(entries);
            }
        } catch (e) {
            batteryHistory = [];
        }
    }

    Process {
        id: loader
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root._applyLoaded(text)
        }
    }

    Process {
        id: saver
    }

    Component.onCompleted: root._loadFromFile()

    Timer {
        interval: 300000 // 5 minutes
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (root.bat) {
                root.hasBattery = true;
                root.batteryPercent = Math.round(root.bat.percentage * 100);
                root.pushToHistory(root.batteryPercent);
            } else {
                root.hasBattery = false;
            }
        }
    }
}
