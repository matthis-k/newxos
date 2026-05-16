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
                Config.colors.blue,
                Config.colors.green,
                Config.colors.yellow,
                Config.colors.red,
                Config.colors.maroon,
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
        title: "Memory"
        Layout.fillWidth: true

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StatTableHeader {}

            StatTableRow {
                label: "RAM"
                valueText: `${SystemStats.memoryUsedMiB} / ${SystemStats.memoryTotalMiB} MiB`
                percent: SystemStats.memoryPercent
                percentColor: SystemStats.memoryPercent >= 90 ? Config.styling.critical : (SystemStats.memoryPercent >= 75 ? Config.styling.warning : Config.styling.text0)
            }

            StatTableRow {
                label: "Swap"
                valueText: SystemStats.swapTotalMiB > 0 ? `${SystemStats.swapUsedMiB} / ${SystemStats.swapTotalMiB} MiB` : "Disabled"
                percent: SystemStats.swapTotalMiB > 0 ? SystemStats.swapPercent : -1
                percentColor: SystemStats.swapPercent >= 90 ? Config.styling.critical : (SystemStats.swapPercent >= 75 ? Config.styling.warning : Config.styling.text0)
            }
        }
    }

    DashboardSection {
        title: "Storage"
        Layout.fillWidth: true

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StatTableHeader {}

            Repeater {
                model: SystemStats.diskPartitions

                StatTableRow {
                    label: modelData.mount
                    valueText: `${modelData.usedGiB} / ${modelData.totalGiB} GiB`
                    percent: modelData.percent
                    percentColor: modelData.percent >= 90 ? Config.styling.critical : (modelData.percent >= 75 ? Config.styling.warning : Config.styling.text0)
                }
            }
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

    component StatTableHeader: RowLayout {
        Layout.fillWidth: true
        spacing: Config.spacing.xs

        Text {
            Layout.fillWidth: true
            text: "Name"
            color: Config.styling.text2
            font.pixelSize: 12
            font.bold: true
        }

        Text {
            Layout.preferredWidth: 120
            horizontalAlignment: Text.AlignRight
            text: "Used / Total"
            color: Config.styling.text2
            font.pixelSize: 12
            font.bold: true
        }

        Text {
            Layout.preferredWidth: 50
            horizontalAlignment: Text.AlignRight
            text: "%"
            color: Config.styling.text2
            font.pixelSize: 12
            font.bold: true
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Config.styling.bg3
        }
    }

    component StatTableRow: RowLayout {
        Layout.fillWidth: true
        spacing: Config.spacing.xs

        property string label: ""
        property string valueText: ""
        property real percent: 0
        property color percentColor: Config.styling.text0

        Text {
            Layout.fillWidth: true
            text: parent.label
            color: Config.styling.text0
            font.pixelSize: 13
            elide: Text.ElideRight
        }

        Text {
            Layout.preferredWidth: 120
            horizontalAlignment: Text.AlignRight
            text: parent.valueText
            color: Config.styling.text1
            font.pixelSize: 13
            font.family: "monospace"
        }

        Text {
            Layout.preferredWidth: 50
            horizontalAlignment: Text.AlignRight
            text: parent.percent >= 0 ? `${Math.round(parent.percent)}%` : "-"
            color: parent.percentColor
            font.pixelSize: 13
            font.bold: true
        }
    }
}
