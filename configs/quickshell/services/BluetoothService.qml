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
    readonly property BluetoothModels bluetoothModels: BluetoothModels {}
    readonly property BluetoothPresentation bluetoothPresentation: BluetoothPresentation {}
    readonly property BluetoothOperationState operationState: BluetoothOperationState {}

    readonly property bool available: !!adapter
    readonly property bool enabled: adapter ? adapter.enabled : false
    readonly property bool blocked: adapter ? adapter.state === BluetoothAdapterState.Blocked : false
    readonly property bool scanning: adapter ? adapter.discovering : false

    readonly property var operation: root.operationState.operation
    readonly property bool busy: root.operationState.busy || scanning
    readonly property bool connected: connectedCount > 0
    readonly property int connectedCount: root.connectedDevices.length

    readonly property string state: {
        if (!adapter) return "unavailable";
        if (adapter.state === BluetoothAdapterState.Blocked) return "blocked";
        if (!adapter.enabled || adapter.state === BluetoothAdapterState.Disabled) return "disabled";
        if (connectedCount > 0) return "connected";
        return "enabled";
    }

    readonly property var devices: root.bluetoothModels.collectDevices(adapter, root.bluetoothPresentation)
    readonly property var connectedDevices: root.bluetoothModels.connectedDevices(root.devices)
    readonly property var otherDevices: root.bluetoothModels.otherDevices(root.devices)
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

    function resolveDevice(deviceOrId) {
        if (!deviceOrId)
            return null;
        if (typeof deviceOrId === "object")
            return deviceOrId;
        return root.rawDeviceById(deviceOrId);
    }

    function deviceKey(device) { return root.bluetoothModels.deviceKey(device); }
    function displayName(device) { return root.bluetoothPresentation.displayName(device); }
    function batteryLabel(device) { return root.bluetoothPresentation.batteryLabel(device); }
    function deviceTypeLabel(device) { return root.bluetoothPresentation.deviceTypeLabel(device); }
    function adapterStatusLabel() { return root.bluetoothPresentation.adapterStatusLabel(root.adapter); }
    function adapterIconName() { return root.bluetoothPresentation.adapterIconName(root.adapter, root.connectedCount); }
    function deviceStatusLabel(device) { return root.bluetoothPresentation.deviceStatusLabel(device); }
    function advancedDeviceInfo(device) { return root.bluetoothPresentation.advancedDeviceInfo(device); }

    function setAdapterEnabled(enabled) {
        root.setEnabled(enabled);
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

    function connectDevice(deviceOrId) {
        const device = root.resolveDevice(deviceOrId);
        const key = root.deviceKey(device) || String(deviceOrId || "");
        root.operationState.beginOperation("connect", key);
        if (device) {
            device.connect();
            root.operationState.finishOperation(true, "");
        } else {
            root.operationState.finishOperation(false, "Bluetooth device not found");
        }
    }

    function disconnectDevice(deviceOrId) {
        const device = root.resolveDevice(deviceOrId);
        const key = root.deviceKey(device) || String(deviceOrId || "");
        root.operationState.beginOperation("disconnect", key);
        if (device) {
            device.disconnect();
            root.operationState.finishOperation(true, "");
        } else {
            root.operationState.finishOperation(false, "Bluetooth device not found");
        }
    }

    function pairDevice(deviceOrId) {
        const device = root.resolveDevice(deviceOrId);
        const key = root.deviceKey(device) || String(deviceOrId || "");
        root.operationState.beginOperation("pair", key);
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

    function pairOrCancelDevice(device) {
        root.pairDevice(device);
    }

    function forgetDevice(deviceOrId) {
        const device = root.resolveDevice(deviceOrId);
        const key = root.deviceKey(device) || String(deviceOrId || "");
        root.operationState.beginOperation("forget", key);
        if (device) {
            device.forget();
            root.operationState.finishOperation(true, "");
        } else {
            root.operationState.finishOperation(false, "Bluetooth device not found");
        }
    }

    function setTrusted(deviceOrId, value) {
        const device = root.resolveDevice(deviceOrId);
        const key = root.deviceKey(device) || String(deviceOrId || "");
        root.operationState.beginOperation("trust", key);
        if (device) {
            device.trusted = value;
            root.operationState.finishOperation(true, "");
        } else {
            root.operationState.finishOperation(false, "Bluetooth device not found");
        }
    }

    function toggleTrusted(device) {
        if (!device)
            return;
        root.setTrusted(device, !device.trusted);
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
