import QtQuick
import qs.services

StatusIcon {
    readonly property var connectedNetwork: NetworkService.connectedNetwork

    function signalBucket(strength) {
        const normalized = Math.max(0, Math.min(1, strength || 0));
        const percent = Math.round(normalized * 100);
        if (percent === 0)
            return "none";
        if (percent < 25)
            return "weak";
        if (percent < 50)
            return "ok";
        if (percent < 75)
            return "good";
        return "excellent";
    }

    iconName: {
        if (NetworkService.hasWiredConnection)
            return "network-wired-symbolic";

        if (!NetworkService.wifiHardwareEnabled)
            return "network-wireless-disabled-symbolic";

        if (connectedNetwork)
            return `network-wireless-signal-${signalBucket(connectedNetwork.signalStrength)}-symbolic`;

        return NetworkService.wifiEnabled ? "network-wireless-offline-symbolic" : "network-wireless-disabled-symbolic";
    }
    tabName: "wifi"
}
