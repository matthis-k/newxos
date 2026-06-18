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
    readonly property bool busy: false
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
                statusText: device.connected ? "Connected" : (device.paired ? "Paired" : "Available"),
                raw: device
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
        if (adapter)
            adapter.enabled = value;
    }

    function toggle() {
        if (adapter)
            adapter.enabled = !adapter.enabled;
    }

    function scan(value) {
        if (adapter)
            adapter.discovering = value;
    }

    function connectDevice(id) {
        const device = rawDeviceById(id);
        if (device)
            device.connect();
    }

    function disconnectDevice(id) {
        const device = rawDeviceById(id);
        if (device)
            device.disconnect();
    }

    function pairDevice(id) {
        const device = rawDeviceById(id);
        if (!device) return;
        if (device.pairing)
            device.cancelPair();
        else
            device.pair();
    }

    function forgetDevice(id) {
        const device = rawDeviceById(id);
        if (device)
            device.forget();
    }

    function setTrusted(id, value) {
        const device = rawDeviceById(id);
        if (device)
            device.trusted = value;
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
            root.adapter.discoveringChanged.connect(function() { root._revision++; });
        }
    }
}
