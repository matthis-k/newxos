import QtQml
import Quickshell.Bluetooth

QtObject {
    id: root

    function normalizeDevices(adapter) {
        if (!adapter) return [];

        const result = [];
        for (const device of (adapter.devices.values || [])) {
            result.push({
                id: device.address || device.dbusPath || "",
                name: device.name || device.deviceName || device.address || "Bluetooth device",
                typeLabel: root.deviceTypeLabel(device),
                iconName: device.icon || "bluetooth-symbolic",
                connected: device.connected || false,
                paired: device.paired || false,
                trusted: device.trusted || false,
                busy: device.state === BluetoothDeviceState.Connecting || device.state === BluetoothDeviceState.Disconnecting || device.pairing,
                batteryPercent: device.batteryAvailable ? Math.round((device.battery || 0) * 100) : null,
                statusText: device.connected ? "Connected" : (device.paired ? "Paired" : "Available")
            });
        }

        result.sort(function(a, b) {
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

    function rawDeviceById(adapter, id) {
        if (!adapter) return null;
        for (const device of (adapter.devices.values || [])) {
            if (device.address === id || device.dbusPath === id || device.name === id)
                return device;
        }
        return null;
    }
}
