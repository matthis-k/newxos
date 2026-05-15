import Quickshell.Services.UPower
import qs.services

StatusIcon {
    readonly property var battery: UPower.displayDevice
    readonly property bool hasBattery: battery?.isLaptopBattery === true

    iconName: {
        if (hasBattery)
            return battery.iconName || "battery-missing-symbolic";

        switch (PowerProfiles.profile) {
        case PowerProfile.PowerSaver:
            return "power-profile-power-saver-symbolic";
        case PowerProfile.Performance:
            return "power-profile-performance-symbolic";
        default:
            return "power-profile-balanced-symbolic";
        }
    }

    iconColor: {
        if (hasBattery) {
            const percentage = Math.round((battery.percentage || 0) * 100);
            if (percentage <= 10)
                return Config.styling.critical;
            if (percentage <= 20)
                return Config.styling.warning;
            return battery.state === UPowerDeviceState.Charging ? Config.styling.good : Config.styling.text0;
        }

        switch (PowerProfiles.profile) {
        case PowerProfile.PowerSaver:
            return Config.styling.good;
        case PowerProfile.Performance:
            return Config.styling.critical;
        default:
            return Config.colors.yellow;
        }
    }

    tabName: "energy"
}
