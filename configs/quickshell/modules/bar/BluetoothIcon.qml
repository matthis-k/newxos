import Quickshell.Bluetooth
import qs.services

StatusIcon {
    id: root
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool btOn: !!adapter && adapter.enabled
    readonly property int connectedCount: adapter ? (adapter.devices.values || []).filter(device => device.connected).length : 0

    function btIconName() {
        if (!adapter)
            return "bluetooth-disabled";
        if (adapter.state === BluetoothAdapterState.Blocked)
            return "bluetooth-disabled";
        if (!adapter.enabled || adapter.state === BluetoothAdapterState.Disabled)
            return "bluetooth-disabled";
        if (connectedCount > 0)
            return "bluetooth-active";
        if (adapter.discovering)
            return "bluetooth-active";
        return "bluetooth-paired";
    }

    iconName: btIconName()
    fallbackIconName: "bluetooth-symbolic"
    iconColor: btOn ? Config.styling.bluetooth : Config.styling.critical

    tabName: "bluetooth"
}
