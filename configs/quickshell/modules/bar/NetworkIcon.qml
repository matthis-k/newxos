import QtQuick
import Quickshell
import qs.services

StatusIcon {
    iconName: NetworkManager.currentNetwork ? NetworkManager.currentNetwork.icon : "network-wireless-offline-symbolic"
    quickmenuName: "network"
}
