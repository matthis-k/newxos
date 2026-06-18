pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.services

Singleton {
    id: root

    readonly property var backend: {
        return {
            network: NetworkService.backend,
            vpn: VpnService.backend,
            bluetooth: BluetoothService.backend
        };
    }

    readonly property bool online: NetworkService.online
    readonly property bool connected: NetworkService.connected || VpnService.connected
    readonly property bool wifiEnabled: NetworkService.wifiEnabled
    readonly property bool wifiConnected: NetworkService.connectedSsid !== ""
    readonly property bool wiredConnected: NetworkService.hasWiredConnection
    readonly property bool vpnConnected: VpnService.connected
    readonly property bool bluetoothEnabled: BluetoothService.enabled
    readonly property bool bluetoothConnected: BluetoothService.connected

    readonly property string state: {
        if (NetworkService.hasWiredConnection) return "wired";
        if (NetworkService.connectedSsid) return "wireless";
        if (wifiEnabled) return "disconnected";
        return "disabled";
    }

    readonly property string iconName: NetworkService.iconName
    readonly property color iconColor: NetworkService.iconColor
    readonly property string label: "Connectivity"
    readonly property string statusText: {
        const parts = [];
        if (NetworkService.connectedSsid) parts.push(NetworkService.connectedSsid);
        else if (NetworkService.hasWiredConnection) parts.push("Wired");
        else if (wifiEnabled) parts.push("No network");
        else parts.push("Wi-Fi off");

        if (VpnService.connected) parts.push("VPN");
        if (BluetoothService.connected) parts.push(`BT:${BluetoothService.connectedCount}`);

        return parts.join(" · ");
    }

    readonly property var presentation: {
        return {
            icon: root.iconName,
            color: root.iconColor,
            label: root.label,
            status: root.statusText,
            state: root.state,
            online: root.online,
            connected: root.connected,
            wifiConnected: root.wifiConnected,
            wiredConnected: root.wiredConnected,
            vpnConnected: root.vpnConnected,
            bluetoothConnected: root.bluetoothConnected,
            wifiEnabled: root.wifiEnabled,
            bluetoothEnabled: root.bluetoothEnabled
        };
    }
}
