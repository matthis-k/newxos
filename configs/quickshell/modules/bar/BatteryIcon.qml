import QtQuick
import Quickshell
import Quickshell.Services.UPower
import qs.services

StatusIcon {
    id: root
    property UPowerDevice bat: UPower.displayDevice
    visible: bat.isLaptopBattery == true

    color: {
        let percentage = Math.floor(root.bat.percentage * 100);
        return [
            {
                max: 10,
                col: Config.styling.critical
            },
            {
                max: 20,
                col: Config.colors.yellow
            },
            {
                max: 60,
                col: Config.styling.text0
            },
            {
                max: 100,
                col: Config.styling.good
            }
        ].find(({
                max,
                col
            }) => percentage <= max).col;
    }

    iconName: root.bat.iconName
    quickmenuName: "battery"
}
