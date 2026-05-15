import QtQuick
import QtQuick.Layouts

import qs.services
import qs.components

DashboardPage {
    id: root

    title: "System stats"
    subtitle: "Compact live system monitor"

    DashboardSection {
        Layout.fillWidth: true
        title: "Live system stats"

        InfoRow {
            Layout.fillWidth: true
            iconName: "processor-symbolic"
            label: "CPU"
            value: `${Math.round(SystemStats.cpuPercent)}%`
            valueColor: SystemStats.cpuPercent >= 90 ? Config.styling.critical : (SystemStats.cpuPercent >= 70 ? Config.styling.warning : Config.styling.text0)
        }

        InfoRow {
            Layout.fillWidth: true
            iconName: "computer-symbolic"
            label: "Memory"
            value: `${SystemStats.memoryUsedMiB}/${SystemStats.memoryTotalMiB} MiB`
        }

        InfoRow {
            Layout.fillWidth: true
            iconName: "media-floppy-symbolic"
            label: "Swap"
            value: SystemStats.swapTotalMiB > 0 ? `${SystemStats.swapUsedMiB}/${SystemStats.swapTotalMiB} MiB` : "Disabled"
        }

        InfoRow {
            Layout.fillWidth: true
            iconName: "drive-harddisk-symbolic"
            label: "Root disk"
            value: `${SystemStats.rootUsedGiB}/${SystemStats.rootTotalGiB} GiB`
        }
    }

    DashboardSection {
        Layout.fillWidth: true
        title: "Network throughput"

        InfoRow {
            Layout.fillWidth: true
            iconName: "go-down-symbolic"
            label: "Download"
            value: SystemStats.formatRate(SystemStats.rxBytesPerSecond)
        }

        InfoRow {
            Layout.fillWidth: true
            iconName: "go-up-symbolic"
            label: "Upload"
            value: SystemStats.formatRate(SystemStats.txBytesPerSecond)
        }
    }
}
