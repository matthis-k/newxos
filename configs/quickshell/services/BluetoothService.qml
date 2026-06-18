pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Bluetooth
import qs.services
import "bluetooth"

Singleton {
    id: root

    readonly property var backend: Bluetooth
    readonly property var adapter: Bluetooth.defaultAdapter

    readonly property BluetoothDeviceNormalizer deviceNormalizer: BluetoothDeviceNormalizer {}
    readonly property BluetoothOperationState operationState: BluetoothOperationState {}

    readonly property bool available: !!adapter
    readonly property bool enabled: adapter ? adapter.enabled : false
    readonly property bool blocked: adapter ? adapter.state === BluetoothAdapterState.Blocked : false
    readonly property bool scanning: adapter ? adapter.discovering : false

    readonly property var operation: root.operationState.operation
    readonly property bool busy: root.operationState.busy || scanning
    readonly property bool connected: connectedCount > 0
    readonly property int connectedCount: adapter ? (adapter.devices.values || []).filter(function(d) { return d.connected; }).length : 0

    readonly property string state: {
        if (!adapter) return "unavailable";
        if (adapter.state === BluetoothAdapterState.Blocked) return "blocked";
        if (!adapter.enabled || adapter.state === BluetoothAdapterState.Disabled) return "disabled";
        if (connectedCount > 0) return "connected";
        return "enabled";
    }

    readonly property var devices: root.deviceNormalizer.normalizeDevices(adapter)
    readonly property var connectedDevices: devices.filter(function(d) { return d.connected; })
    readonly property var availableDevices: devices

    property var _revision: 0

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

    function rawDeviceById(id) {
        return root.deviceNormalizer.rawDeviceById(adapter, id);
    }

    function setEnabled(value) {
        if (adapter) {
            root.operationState.beginOperation("toggle", "adapter");
            adapter.enabled = value;
            root.operationState.finishOperation(true, "");
        }
    }

    function toggle() {
        if (adapter) {
            root.operationState.beginOperation("toggle", "adapter");
            adapter.enabled = !adapter.enabled;
            root.operationState.finishOperation(true, "");
        }
    }

    function scan(value) {
        if (adapter) {
            root.operationState.beginOperation("scan", value ? "on" : "off");
            adapter.discovering = value;
            if (!value)
                root.operationState.finishOperation(true, "");
        }
    }

    function connectDevice(id) {
        const device = root.rawDeviceById(id);
        root.operationState.beginOperation("connect", id);
        if (device) {
            device.connect();
            root.operationState.finishOperation(true, "");
        } else {
            root.operationState.finishOperation(false, "Bluetooth device not found");
        }
    }

    function disconnectDevice(id) {
        const device = root.rawDeviceById(id);
        root.operationState.beginOperation("disconnect", id);
        if (device) {
            device.disconnect();
            root.operationState.finishOperation(true, "");
        } else {
            root.operationState.finishOperation(false, "Bluetooth device not found");
        }
    }

    function pairDevice(id) {
        const device = root.rawDeviceById(id);
        root.operationState.beginOperation("pair", id);
        if (!device) {
            root.operationState.finishOperation(false, "Bluetooth device not found");
            return;
        }
        if (device.pairing)
            device.cancelPair();
        else
            device.pair();
        root.operationState.finishOperation(true, "");
    }

    function forgetDevice(id) {
        const device = root.rawDeviceById(id);
        root.operationState.beginOperation("forget", id);
        if (device) {
            device.forget();
            root.operationState.finishOperation(true, "");
        } else {
            root.operationState.finishOperation(false, "Bluetooth device not found");
        }
    }

    function setTrusted(id, value) {
        const device = root.rawDeviceById(id);
        root.operationState.beginOperation("trust", id);
        if (device) {
            device.trusted = value;
            root.operationState.finishOperation(true, "");
        } else {
            root.operationState.finishOperation(false, "Bluetooth device not found");
        }
    }

    function executePayload(payload) {
        if (!payload) return false;
        switch (payload.op) {
        case "setEnabled": root.setEnabled(!!payload.enabled); return true;
        case "toggle": root.toggle(); return true;
        case "scan": root.scan(!!payload.enabled); return true;
        case "connect": root.connectDevice(payload.id); return true;
        case "disconnect": root.disconnectDevice(payload.id); return true;
        case "pair": root.pairDevice(payload.id); return true;
        case "forget": root.forgetDevice(payload.id); return true;
        case "trust": root.setTrusted(payload.id, !!payload.trusted); return true;
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
                if (!root.adapter.discovering && root.operationState.currentOperationKind === "scan")
                    root.operationState.finishOperation(true, "");
            });
        }
    }
}
