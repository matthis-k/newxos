import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import qs.services

StatusIcon {
    id: root
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var battery: UPower.displayDevice
    readonly property bool muted: sink?.audio?.muted || false
    readonly property bool batteryCritical: !!battery && battery.isLaptopBattery === true && (battery.percentage || 0) <= 0.1
    readonly property bool networkOffline: !NetworkService.connectedSsid && !NetworkService.hasWiredConnection

    iconName: "view-grid-symbolic"
    iconColor: {
        if (NotificationCenter.hasCritical || batteryCritical)
            return Config.styling.critical;
        if (muted || networkOffline)
            return Config.styling.warning;
        return Config.styling.primaryAccent;
    }
    tabName: "overview"
}
