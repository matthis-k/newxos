import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import Quickshell.Io
import Quickshell.Services.Pipewire

import qs.services
import qs.components
import qs.utils

DashboardPage {
    id: root

    title: "Overview"

    property var screenState: null

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property var adapter: Bluetooth.defaultAdapter

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
                onToggled: function (checked) {
                    NetworkService.setWifiEnabled(checked);
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
                onToggled: function (checked) {
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
            title: Utils.nodeName(root.sink, "No output device")
            iconName: Utils.volumeIconName(root.sink, false)
            iconColor: Utils.isMuted(root.sink) ? Config.styling.critical : Config.styling.text0
            valueText: root.sink ? `${Utils.volumePercent(root.sink)}%` : ""
            from: 0; to: 150
            value: Utils.volumePercent(root.sink)
            stepSize: 1
            iconEnabled: !!root.sink
            sliderEnabled: !!root.sink && !Utils.isMuted(root.sink)
            accentColor: Utils.isMuted(root.sink) ? Config.styling.critical : Config.colors.blue
            onIconClicked: Utils.toggleMute(root.sink)
            onValueModified: value => Utils.setVolume(root.sink, value)
        }

        AudioDeviceCard {
            title: Utils.nodeName(root.source, "No input device")
            iconName: Utils.volumeIconName(root.source, true)
            iconColor: Utils.isMuted(root.source) ? Config.styling.critical : Config.styling.text0
            valueText: root.source ? `${Utils.volumePercent(root.source)}%` : ""
            from: 0; to: 150
            value: Utils.volumePercent(root.source)
            stepSize: 1
            iconEnabled: !!root.source
            sliderEnabled: !!root.source && !Utils.isMuted(root.source)
            accentColor: Utils.isMuted(root.source) ? Config.styling.critical : Config.colors.blue
            onIconClicked: Utils.toggleMute(root.source)
            onValueModified: value => Utils.setVolume(root.source, value)
        }
    }

    DashboardSection {
        Layout.fillWidth: true
        title: "Brightness"
        visible: Brightness.available

        LabeledSlider {
            Layout.fillWidth: true
            label: "Display"
            iconName: Brightness.iconName
            value: Brightness.percent
            from: 0
            to: 100
            valueText: Brightness.available ? `${Brightness.percent}%` : "Unavailable"
            enabled: Brightness.available
            onValueCommitted: val => Brightness.setPercent(val)
        }
    }

    DashboardSection {
        Layout.fillWidth: true
        title: "Battery and power"
        visible: Stats.hasBattery

        Battery {
            id: batteryContent
            Layout.fillWidth: true
            showGraph: false
        }
    }

    NavigableSectionHeader {
        Layout.fillWidth: true
        title: "Notifications"
        screenState: root.screenState
        targetTab: "notifications"

        InfoRow {
            Layout.fillWidth: true
            iconName: "bell-symbolic"
            label: "Status"
            value: NotificationCenter.doNotDisturbEnabled ? "Do Not Disturb" : `${NotificationCenter.count} unread`
        }
    }

    NavigableSectionHeader {
        Layout.fillWidth: true
        title: "System stats"
        screenState: root.screenState
        targetTab: "stats"

        InfoRow {
            Layout.fillWidth: true
            iconName: "processor-symbolic"
            label: "CPU"
            value: `${Math.round(Stats.cpuPercent)}%`
            valueColor: Stats.cpuPercent >= 90 ? Config.styling.critical : (Stats.cpuPercent >= 70 ? Config.styling.warning : Config.styling.text0)
        }

        InfoRow {
            Layout.fillWidth: true
            iconName: "computer-symbolic"
            label: "Memory"
            value: `${Stats.memoryUsedMiB}/${Stats.memoryTotalMiB} MiB`
        }
    }

}
