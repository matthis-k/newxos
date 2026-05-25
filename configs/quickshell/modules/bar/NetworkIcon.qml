import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components

StatusIcon {
    id: root

    readonly property var connectedNetwork: NetworkService.connectedNetwork

    iconName: {
        if (NetworkService.hasWiredConnection)
            return "network-wired-symbolic";

        if (!NetworkService.wifiHardwareEnabled)
            return "network-wireless-disabled-symbolic";

        if (connectedNetwork)
            return NetworkService.wifiIconName(connectedNetwork);

        return NetworkService.wifiEnabled ? "network-wireless-offline-symbolic" : "network-wireless-disabled-symbolic";
    }
    tabName: "wifi"

    contentItem: Item {
        implicitWidth: root.implicitWidth
        implicitHeight: root.implicitHeight

        Icon {
            id: statusIcon
            anchors.centerIn: parent
            iconName: root.iconName
            fallbackIconName: root.fallbackIconName
            color: root.iconColor
            implicitSize: (parent ? parent.height : root.implicitHeight) * 0.7
        }

        Icon {
            anchors.bottom: statusIcon.bottom
            anchors.right: statusIcon.right
            anchors.bottomMargin: -2
            anchors.rightMargin: -3
            iconName: "network-vpn-symbolic"
            color: NordVPN.connected ? Config.styling.good : Config.styling.critical
            implicitSize: statusIcon.implicitSize * 0.55
            visible: NordVPN.available
        }

        Badge {
            anchors.top: statusIcon.top
            anchors.right: statusIcon.right
            anchors.topMargin: -Config.spacing.xxs
            anchors.rightMargin: -Config.spacing.xxs
            text: root.badgeText
            badgeColor: root.badgeColor
        }
    }
}
