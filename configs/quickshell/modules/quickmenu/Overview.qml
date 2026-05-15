import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import Quickshell.Io
import Quickshell.Services.Pipewire

import qs.services
import qs.components

DashboardPage {
    id: root

    title: "Overview"

    property var screenState: null

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property var adapter: Bluetooth.defaultAdapter

    scrollable: false
    fillHeight: false

    function nodeName(node, fallback) {
        if (!node)
            return fallback;
        return node.nickname || node.description || node.name || fallback;
    }

    function volumePercent(node) {
        return node && node.audio ? Math.round((node.audio.volume || 0) * 100) : 0;
    }

    function setVolume(node, percent) {
        if (!node || !node.audio)
            return;
        node.audio.volume = Math.max(0, Math.min(1.5, percent / 100));
    }

    function toggleMute(node) {
        if (!node || !node.audio)
            return;
        node.audio.muted = !node.audio.muted;
    }

    function volumeIconName(node, inputNode) {
        if (!node || !node.audio)
            return inputNode ? "audio-input-microphone-symbolic" : "audio-volume-muted-symbolic";
        if (node.audio.muted)
            return inputNode ? "microphone-sensitivity-muted-symbolic" : "audio-volume-muted-symbolic";
        const vol = node.audio.volume || 0;
        if (inputNode)
            return vol <= 0.001 ? "microphone-sensitivity-muted-symbolic" : "audio-input-microphone-symbolic";
        if (vol <= 0.001)
            return "audio-volume-muted-symbolic";
        if (vol < 0.34)
            return "audio-volume-low-symbolic";
        if (vol < 0.67)
            return "audio-volume-medium-symbolic";
        return "audio-volume-high-symbolic";
    }

    function connectedBluetoothCount() {
        if (!root.adapter)
            return 0;

        let count = 0;
        for (const device of root.adapter.devices.values || []) {
            if (device && device.connected)
                count += 1;
        }
        return count;
    }

    readonly property string connectionSummary: {
        if (NetworkService.hasWiredConnection)
            return `${NetworkService.wiredDeviceName} connected`;
        if (NetworkService.connectedSsid)
            return NetworkService.connectedSsid;
        return NetworkService.wifiEnabled ? "No active network" : "Wi-Fi disabled";
    }

    readonly property string bluetoothSummary: {
        if (!root.adapter)
            return "No adapter available";
        if (!root.adapter.enabled)
            return "Bluetooth disabled";
        const count = connectedBluetoothCount();
        return count > 0 ? `${count} connected` : "Ready to connect";
    }

    DashboardSection {
        Layout.fillWidth: true
        title: "Session"

        SessionActionsGrid {
            Layout.fillWidth: true
        }
    }

    DashboardSection {
        Layout.fillWidth: true
        title: "Connectivity"

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Config.spacing.xs

            DashboardSwitchRow {
                Layout.fillWidth: true
                label: "Wi-Fi"
                subtitle: root.connectionSummary
                iconName: NetworkService.wifiEnabled ? "network-wireless-symbolic" : "network-wireless-offline-symbolic"
                iconColor: NetworkService.wifiEnabled ? Config.styling.primaryAccent : Config.styling.text1
                enabled: NetworkService.wifiHardwareEnabled
                checked: NetworkService.wifiEnabled
                onToggled: function(checked) {
                    overviewWifiToggleProcess.exec({
                        command: checked
                            ? ["nmcli", "radio", "wifi", "on"]
                            : ["nmcli", "radio", "wifi", "off"]
                    });
                }
            }

            DashboardSwitchRow {
                Layout.fillWidth: true
                label: "Bluetooth"
                subtitle: root.bluetoothSummary
                iconName: root.adapter && root.adapter.enabled ? "bluetooth-symbolic" : "bluetooth-disabled-symbolic"
                iconColor: root.adapter && root.adapter.enabled ? Config.styling.bluetooth : Config.styling.text1
                enabled: !!root.adapter
                checked: !!root.adapter && root.adapter.enabled
                onToggled: function(checked) {
                    if (root.adapter)
                        root.adapter.enabled = checked;
                }
            }
        }
    }

    DashboardSection {
        Layout.fillWidth: true
        title: "Audio"

        AudioDeviceCard {
            title: root.nodeName(root.sink, "No output device")
            iconName: root.volumeIconName(root.sink, false)
            iconColor: root.sink?.audio?.muted ? Config.styling.critical : Config.styling.text0
            valueText: root.sink ? `${root.volumePercent(root.sink)}%` : ""
            from: 0
            to: 150
            value: root.volumePercent(root.sink)
            stepSize: 1
            iconEnabled: !!root.sink
            sliderEnabled: !!root.sink && !root.sink?.audio?.muted
            accentColor: root.sink?.audio?.muted ? Config.styling.critical : Config.colors.blue
            onIconClicked: root.toggleMute(root.sink)
            onValueModified: (value) => root.setVolume(root.sink, value)
        }

        AudioDeviceCard {
            title: root.nodeName(root.source, "No input device")
            iconName: root.volumeIconName(root.source, true)
            iconColor: root.source?.audio?.muted ? Config.styling.critical : Config.styling.text0
            valueText: root.source ? `${root.volumePercent(root.source)}%` : ""
            from: 0
            to: 150
            value: root.volumePercent(root.source)
            stepSize: 1
            iconEnabled: !!root.source
            sliderEnabled: !!root.source && !root.source?.audio?.muted
            accentColor: root.source?.audio?.muted ? Config.styling.critical : Config.colors.blue
            onIconClicked: root.toggleMute(root.source)
            onValueModified: (value) => root.setVolume(root.source, value)
        }
    }

    DashboardSection {
        Layout.fillWidth: true
        title: "Brightness"

        LabeledSlider {
            Layout.fillWidth: true
            label: "Display"
            iconName: Brightness.iconName
            value: Brightness.percent
            from: 0
            to: 100
            valueText: Brightness.available ? `${Brightness.percent}%` : "Unavailable"
            enabled: Brightness.available
            onValueCommitted: (val) => Brightness.setPercent(val)
        }
    }

    DashboardSection {
        Layout.fillWidth: true
        title: "Battery and power"

        Battery {
            id: batteryContent
            Layout.fillWidth: true
        }
    }

    DashboardSection {
        Layout.fillWidth: true
        title: "Notifications"
    }

    Process {
        id: overviewWifiToggleProcess

        function onExited(exitCode) {
            if (exitCode === 0)
                NetworkService.refresh();
        }
    }
}
