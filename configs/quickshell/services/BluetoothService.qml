pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Bluetooth
import qs.services

Singleton {
    id: root

    readonly property var backend: Bluetooth
    readonly property var adapter: Bluetooth.defaultAdapter

    readonly property bool available: !!adapter
    readonly property bool enabled: adapter ? adapter.enabled : false
    readonly property bool blocked: adapter ? adapter.state === BluetoothAdapterState.Blocked : false
    readonly property bool scanning: adapter ? adapter.discovering : false
    property string currentOperationKind: ""
    property string currentOperationTarget: ""
    property bool currentOperationRunning: false
    property string currentOperationLastError: ""

    readonly property var operation: ({
        kind: currentOperationKind,
        target: currentOperationTarget,
        running: currentOperationRunning,
        lastError: currentOperationLastError
    })
    readonly property bool busy: currentOperationRunning || scanning
    readonly property bool connected: connectedCount > 0
    readonly property int connectedCount: adapter ? (adapter.devices.values || []).filter(d => d.connected).length : 0

    readonly property string state: {
        if (!adapter) return "unavailable";
        if (adapter.state === BluetoothAdapterState.Blocked) return "blocked";
        if (!adapter.enabled || adapter.state === BluetoothAdapterState.Disabled) return "disabled";
        if (connectedCount > 0) return "connected";
        return "enabled";
    }

    readonly property var devices: normalizeDevices()
    readonly property var connectedDevices: devices.filter(d => d.connected)
    readonly property var availableDevices: devices

    property var _revision: 0

    function beginOperation(kind, target) {
        currentOperationKind = kind || "";
        currentOperationTarget = target || "";
        currentOperationRunning = true;
        currentOperationLastError = "";
    }

    function finishOperation(success, message) {
        currentOperationRunning = false;
        currentOperationLastError = success ? "" : (message || `${currentOperationKind || "operation"} failed`);
    }

    readonly property string iconName: {
        if (!adapter) return "bluetooth-disabled";
        if (adapter.state === BluetoothAdapterState.Blocked) return "bluetooth-disabled";
        if (!adapter.enabled || adapter.state === BluetoothAdapterState.Disabled) return "bluetooth-disabled";
        if (connectedCount > 0) return "bluetooth-active";
        if (adapter.discovering) return "bluetooth-active";
        return "bluetooth-paired";
    }

    readonly property color iconColor: enabled ? Config.styling.bluetooth : Config.styling.critical
    readonly property string label: "Bluetooth"
    readonly property string statusText: {
        if (!adapter) return "No adapter";
        if (!enabled) return "Disabled";
        if (connectedCount > 0) return `${connectedCount} connected`;
        if (scanning) return "Scanning";
        return "Ready";
    }

    readonly property var presentation: {
        return {
            icon: root.iconName,
            color: root.iconColor,
            label: root.label,
            status: root.statusText,
            state: root.state,
            available: root.available,
            enabled: root.enabled,
            connected: root.connected,
            connectedCount: root.connectedCount
        };
    }

    function normalizeDevices() {
        const _ = root._revision;
        if (!adapter) return [];

        const result = [];
        for (const device of (adapter.devices.values || [])) {
            result.push({
                id: device.address || device.dbusPath || "",
                name: device.name || device.deviceName || device.address || "Bluetooth device",
                typeLabel: deviceTypeLabel(device),
                iconName: device.icon || "bluetooth-symbolic",
                connected: device.connected || false,
                paired: device.paired || false,
                trusted: device.trusted || false,
                busy: device.state === BluetoothDeviceState.Connecting || device.state === BluetoothDeviceState.Disconnecting || device.pairing,
                batteryPercent: device.batteryAvailable ? Math.round((device.battery || 0) * 100) : null,
                statusText: device.connected ? "Connected" : (device.paired ? "Paired" : "Available")
            });
        }

        result.sort((a, b) => {
            if (a.connected !== b.connected) return a.connected ? -1 : 1;
            if (a.paired !== b.paired) return a.paired ? -1 : 1;
            return a.name.localeCompare(b.name);
        });

        return result;
    }

    function deviceTypeLabel(device) {
        const icon = (device?.icon || "").replace(/-symbolic$/, "");
        if (icon.includes("headphones")) return "Headphones";
        if (icon.includes("headset")) return "Headset";
        if (icon.includes("speaker")) return "Speaker";
        if (icon.includes("audio")) return "Audio device";
        if (icon.includes("mouse")) return "Mouse";
        if (icon.includes("keyboard")) return "Keyboard";
        if (icon.includes("gamepad") || icon.includes("joystick")) return "Controller";
        if (icon.includes("phone")) return "Phone";
        if (icon.includes("computer") || icon.includes("laptop")) return "Computer";
        if (icon.includes("tablet")) return "Tablet";
        if (icon.includes("watch")) return "Watch";
        return "Bluetooth device";
    }

    function rawDeviceById(id) {
        if (!adapter) return null;
        for (const device of (adapter.devices.values || [])) {
            if (device.address === id || device.dbusPath === id || device.name === id)
                return device;
        }
        return null;
    }

    function setEnabled(value) {
        if (adapter) {
            beginOperation("toggle", "adapter");
            adapter.enabled = value;
            finishOperation(true, "");
        }
    }

    function toggle() {
        if (adapter) {
            beginOperation("toggle", "adapter");
            adapter.enabled = !adapter.enabled;
            finishOperation(true, "");
        }
    }

    function scan(value) {
        if (adapter) {
            beginOperation("scan", value ? "on" : "off");
            adapter.discovering = value;
            if (!value)
                finishOperation(true, "");
        }
    }

    function connectDevice(id) {
        const device = rawDeviceById(id);
        if (device) {
            beginOperation("connect", id);
            device.connect();
            finishOperation(true, "");
        } else {
            beginOperation("connect", id);
            finishOperation(false, "Bluetooth device not found");
        }
    }

    function disconnectDevice(id) {
        const device = rawDeviceById(id);
        if (device) {
            beginOperation("disconnect", id);
            device.disconnect();
            finishOperation(true, "");
        } else {
            beginOperation("disconnect", id);
            finishOperation(false, "Bluetooth device not found");
        }
    }

    function pairDevice(id) {
        const device = rawDeviceById(id);
        beginOperation("pair", id);
        if (!device) {
            finishOperation(false, "Bluetooth device not found");
            return;
        }
        if (device.pairing)
            device.cancelPair();
        else
            device.pair();
        finishOperation(true, "");
    }

    function forgetDevice(id) {
        const device = rawDeviceById(id);
        if (device) {
            beginOperation("forget", id);
            device.forget();
            finishOperation(true, "");
        } else {
            beginOperation("forget", id);
            finishOperation(false, "Bluetooth device not found");
        }
    }

    function setTrusted(id, value) {
        const device = rawDeviceById(id);
        if (device) {
            beginOperation("trust", id);
            device.trusted = value;
            finishOperation(true, "");
        } else {
            beginOperation("trust", id);
            finishOperation(false, "Bluetooth device not found");
        }
    }

    function executePayload(payload) {
        if (!payload) return false;
        switch (payload.op) {
        case "setEnabled": setEnabled(!!payload.enabled); return true;
        case "toggle": toggle(); return true;
        case "scan": scan(!!payload.enabled); return true;
        case "connect": connectDevice(payload.id); return true;
        case "disconnect": disconnectDevice(payload.id); return true;
        case "pair": pairDevice(payload.id); return true;
        case "forget": forgetDevice(payload.id); return true;
        case "trust": setTrusted(payload.id, !!payload.trusted); return true;
        default: return false;
        }
    }

    Connections {
        target: Bluetooth
        function onDefaultAdapterChanged() { root._revision++; }
    }

    onAdapterChanged: {
        if (root.adapter) {
            root.adapter.enabledChanged.connect(function() { root._revision++; });
            if (root.adapter.devicesChanged)
                root.adapter.devicesChanged.connect(function() { root._revision++; });
            root.adapter.discoveringChanged.connect(function() {
                root._revision++;
                if (!root.adapter.discovering && root.currentOperationKind === "scan")
                    root.finishOperation(true, "");
            });
        }
    }
}
