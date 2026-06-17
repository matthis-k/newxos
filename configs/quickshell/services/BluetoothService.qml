import QtQuick
import Quickshell
import Quickshell.Bluetooth
import qs.services

QtObject {
    id: root

    property QtObject backend: Bluetooth

    readonly property bool enabled: root.adapter ? root.adapter.enabled : false
    readonly property var adapter: Bluetooth.defaultAdapter

    property int _connectedCount: 0

    readonly property string iconName: {
        if (!root.enabled) return "bluetooth-disabled";
        if (root.adapter && root.adapter.state === BluetoothAdapterState.Blocked) return "bluetooth-disabled";
        if (root._connectedCount > 0) return "bluetooth-active";
        if (root.adapter && root.adapter.discovering) return "bluetooth-active";
        return "bluetooth-paired";
    }

    readonly property color iconColor: root.enabled ? Config.styling.bluetooth : Config.styling.critical

    Connections {
        target: Bluetooth
        function onDefaultAdapterChanged() { root._retarget(); }
    }

    Connections {
        id: _adapterWatch
        function onEnabledChanged() { root._recalc(); }
        function onDevicesChanged() { root._recalc(); }
        function onDiscoveringChanged() { root._recalc(); }
    }

    function _retarget() {
        _adapterWatch.target = Bluetooth.defaultAdapter;
        root._recalc();
    }

    function _recalc() {
        var ad = root.adapter;
        if (!ad) {
            root._connectedCount = 0;
            return;
        }
        root._connectedCount = (ad.devices.values || []).filter(function(d) { return d.connected; }).length;
    }
}
