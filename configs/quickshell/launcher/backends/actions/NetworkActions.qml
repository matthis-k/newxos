import QtQml
import qs.services

QtObject {
    function roots(context) { return [{ id: "network", aliases: ["net", "network", "networking"], title: qsTr("Networking"), icon: "network-wireless-symbolic", iconColor: Config.styling.primaryAccent, template: "flat-action-group", groupOptions: { flattenAllChildrenOnParentMatch: true, maxNestedChildren: 8 }, behavior: { filterable: true }, children: [
        { id: "wifi", aliases: ["wifi", "wi-fi"], title: qsTr("Wi-Fi"), icon: "network-wireless-symbolic", iconColor: NetworkService.wifiEnabled ? Config.styling.primaryAccent : Config.styling.text1, template: "switch", switchState: NetworkService.wifiEnabled, switchActions: {
            toggle: { id: "toggle", title: qsTr("Toggle"), state: null, payload: { service: "network", op: "toggleWifi" } },
            on: { id: "on", title: qsTr("On"), state: true, payload: { service: "network", op: "setWifiEnabled", enabled: true } },
            off: { id: "off", title: qsTr("Off"), state: false, payload: { service: "network", op: "setWifiEnabled", enabled: false } }
        } },
        { id: "vpn", aliases: ["vpn", "nordvpn", "connect to"], title: qsTr("VPN"), icon: "network-vpn-symbolic", iconColor: VpnService.connected || VpnService.connecting ? Config.styling.good : Config.styling.warning, template: "switch", switchState: VpnService.connected || VpnService.connecting, behavior: { filterable: true, depthPenalty: 1, exploration: { descend: false } }, childVisible: ["expand-on-trailing-space"], groupOptions: { showAllChildrenOnParentMatch: false, flattenAllChildrenOnParentMatch: false, maxNestedChildren: 8 }, switchActions: {
            toggle: { id: "toggle", title: qsTr("Toggle"), state: null, payload: { service: "vpn", op: "toggle" } },
            on: { id: "on", title: qsTr("On"), state: true, payload: { service: "vpn", op: "connect" } },
            off: { id: "off", title: qsTr("Off"), state: false, payload: { service: "vpn", op: "disconnect" } }
        }, children: vpnChildren() },
        { id: "bluetooth", aliases: ["bt", "bluetooth"], title: qsTr("Bluetooth"), icon: BluetoothService.iconName, iconColor: BluetoothService.enabled ? Config.styling.bluetooth : Config.styling.text1, template: "switch", switchState: BluetoothService.enabled, switchActions: {
            toggle: { id: "toggle", title: qsTr("Toggle"), state: null, payload: { service: "bluetooth", op: "toggle" } },
            on: { id: "on", title: qsTr("On"), state: true, payload: { service: "bluetooth", op: "setEnabled", enabled: true } },
            off: { id: "off", title: qsTr("Off"), state: false, payload: { service: "bluetooth", op: "setEnabled", enabled: false } }
        } }
    ] }]; }

    function vpnChildren() { return (VpnService.destinations || []).slice().sort(function(a, b) { return vpnDestinationRank(a) - vpnDestinationRank(b) || String(a.label || a.name || "").localeCompare(String(b.label || b.name || "")); }).map(function(d) { return { id: d.id, aliases: [d.label], title: d.label, subtitle: d.subtext, icon: "network-vpn-symbolic", iconColor: d.kind === "group" ? Config.styling.info : Config.styling.good, action: { service: "vpn", op: "connect", destination: d.value } }; }); }
    function vpnDestinationRank(destination) { return destination.kind === "fastest" ? 0 : destination.kind === "group" ? 1 : 2; }
}
