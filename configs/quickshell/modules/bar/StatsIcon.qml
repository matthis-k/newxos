import qs.services

StatusIcon {
    id: root
    iconName: "utilities-system-monitor-symbolic"
    iconColor: {
        if (SystemStats.cpuPercent >= 90 || SystemStats.memoryPercent >= 90)
            return Config.styling.critical;
        if (SystemStats.cpuPercent >= 70 || SystemStats.memoryPercent >= 75)
            return Config.styling.warning;
        return Config.styling.text0;
    }
    tabName: "stats"
}
