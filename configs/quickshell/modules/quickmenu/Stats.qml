import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import qs.services
import qs.components

DashboardPage {
    id: root

    title: "System stats"

    DashboardSection {
        title: "CPU Usage"
        Layout.fillWidth: true

        CpuGraph {
            id: graph
            active: root.SwipeView.isCurrentItem
            seriesList: {
                const all = [SystemStats.cpuHistory];
                for (let i = 0; i < SystemStats.cpuCoreHistory.length; i++) {
                    all.push(SystemStats.cpuCoreHistory[i] || []);
                }
                return all;
            }
            seriesColors: [
                Config.styling.primaryAccent,
                Config.styling.good,
                Config.styling.warning,
                Config.styling.critical,
                Config.styling.secondaryAccent,
                Config.styling.info,
                Config.styling.urgent,
                Config.styling.bluetooth,
                Config.colors.peach,
                Config.colors.mauve,
                Config.colors.pink,
                Config.colors.flamingo,
                Config.colors.rosewater
            ]
            Layout.fillWidth: true
        }
    }

    DashboardSection {
        title: "Live system stats"
        Layout.fillWidth: true

        InfoRow {
            iconName: "processor-symbolic"
            label: "CPU"
            value: `${Math.round(SystemStats.cpuPercent)}%`
            valueColor: SystemStats.cpuPercent >= 90 ? Config.styling.critical : (SystemStats.cpuPercent >= 70 ? Config.styling.warning : Config.styling.text0)
            Layout.fillWidth: true
        }

        InfoRow {
            iconName: "computer-symbolic"
            label: "Memory"
            value: `${SystemStats.memoryUsedMiB}/${SystemStats.memoryTotalMiB} MiB`
            Layout.fillWidth: true
        }

        InfoRow {
            iconName: "media-floppy-symbolic"
            label: "Swap"
            value: SystemStats.swapTotalMiB > 0 ? `${SystemStats.swapUsedMiB}/${SystemStats.swapTotalMiB} MiB` : "Disabled"
            Layout.fillWidth: true
        }

        InfoRow {
            iconName: "drive-harddisk-symbolic"
            label: "Root disk"
            value: `${SystemStats.rootUsedGiB}/${SystemStats.rootTotalGiB} GiB`
            Layout.fillWidth: true
        }
    }

    DashboardSection {
        title: "Network throughput"
        Layout.fillWidth: true

        InfoRow {
            iconName: "go-down-symbolic"
            label: "Download"
            value: SystemStats.formatRate(SystemStats.rxBytesPerSecond)
            Layout.fillWidth: true
        }

        InfoRow {
            iconName: "go-up-symbolic"
            label: "Upload"
            value: SystemStats.formatRate(SystemStats.txBytesPerSecond)
            Layout.fillWidth: true
        }
    }
}
