import QtQuick
import Quickshell
import Quickshell.Services.UPower
import qs.services

StatusIcon {
    id: root
    property UPowerDevice bat: UPower.displayDevice
    visible: bat?.isLaptopBattery === true

    iconColor: {
        const percentage = Math.floor((bat?.percentage || 0) * 100);
        percentage <= 10 ? Config.styling.critical :
        percentage <= 20 ? Config.colors.yellow :
        percentage <= 60 ? Config.styling.text0 :
        Config.styling.good;
    }

    iconName: bat?.iconName || "battery-missing-symbolic"
    tabName: "energy"
}
