pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import qs.services
import qs.components

DashboardPage {
    id: root

    title: "System stats"
    scrollable: true

    readonly property var cpuCoreColors: [
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
    readonly property color ramColor: Config.colors.mauve
    readonly property color swapColor: Config.colors.blue

    function cpuSeriesOrder(left, right) {
        if (left === "avg")
            return 1;
        if (right === "avg")
            return -1;

        const leftCore = parseInt(String(left).replace("core", ""));
        const rightCore = parseInt(String(right).replace("core", ""));
        if (!isNaN(leftCore) && !isNaN(rightCore))
            return leftCore - rightCore;

        return String(left).localeCompare(String(right));
    }

    function cpuCoreNames() {
        const _ = cpuGraph._revision;
        return cpuGraph.dataSetNames().filter(name => name !== "avg");
    }

    DashboardSection {
        title: "CPU Usage"
        Layout.fillWidth: true

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Config.spacing.xs

            GraphView {
                id: cpuGraph
                active: root.SwipeView.isCurrentItem
                yMin: 0
                yMax: 100
                xWindowMs: 120000
                sampleIntervalMs: 2000
                cacheEnabled: true
                cacheKey: "cpu"
                renderOrderCompare: root.cpuSeriesOrder
                dataSets: {
                    const _ = SystemStats._tick;
                    const all = [];
                    if (!SystemStats._hasCpuDelta)
                        return all;

                    all.push({ name: "avg", value: SystemStats.cpuPercent, color: Config.colors.blue, visible: true });

                    for (let i = 0; i < SystemStats.cpuCorePercents.length; i++)
                        all.push({ name: `core${i}`, value: SystemStats.cpuCorePercents[i], color: root.cpuCoreColors[i % root.cpuCoreColors.length], visible: false });
                    return all;
                }
                Layout.fillWidth: true
                Layout.preferredHeight: 180
                Layout.minimumHeight: 140
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Item { Layout.fillWidth: true }
                CpuLegendButton {
                    Layout.preferredWidth: 100
                    Layout.alignment: Qt.AlignHCenter
                    seriesName: "avg"
                }
                Item { Layout.fillWidth: true }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 4
                rowSpacing: 2
                columnSpacing: 8
                uniformCellWidths: true

                Repeater {
                    model: {
                        const _ = cpuGraph._revision;
                        return root.cpuCoreNames().length;
                    }
                    CpuLegendDelegate {}
                }
            }
        }
    }

    DashboardSection {
        title: "Memory"
        Layout.fillWidth: true

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Config.spacing.xs

            GraphView {
                id: memGraph
                active: root.SwipeView.isCurrentItem
                yMin: 0
                yMax: 100
                xWindowMs: 300000
                sampleIntervalMs: 10000
                cacheEnabled: true
                cacheKey: "memory"
                dataSets: {
                    const _ = SystemStats._tick;
                    return [{
                        name: "RAM",
                        value: SystemStats.memoryPercent,
                        color: root.ramColor,
                        visible: true
                    }, {
                        name: "Swap",
                        value: SystemStats.swapTotalMiB > 0 ? SystemStats.swapPercent : 0,
                        color: root.swapColor,
                        visible: true
                    }];
                }
                Layout.fillWidth: true
                Layout.preferredHeight: 160
                Layout.minimumHeight: 120
            }

            StatTableHeader {}

            StatTableRow {
                label: "RAM"
                valueText: `${SystemStats.memoryUsedMiB} / ${SystemStats.memoryTotalMiB} MiB`
                percent: SystemStats.memoryPercent
                rowColor: root.ramColor
                percentColor: root.ramColor
            }

            StatTableRow {
                label: "Swap"
                valueText: SystemStats.swapTotalMiB > 0 ? `${SystemStats.swapUsedMiB} / ${SystemStats.swapTotalMiB} MiB` : "Disabled"
                percent: SystemStats.swapTotalMiB > 0 ? SystemStats.swapPercent : -1
                rowColor: root.swapColor
                percentColor: root.swapColor
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

                PartitionRow {}
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
        property color rowColor: Config.styling.text0
        property color percentColor: Config.styling.text0

        Text {
            Layout.fillWidth: true
            text: parent.label
            color: parent.rowColor
            font.pixelSize: 13
            elide: Text.ElideRight
        }

        Text {
            Layout.preferredWidth: 120
            horizontalAlignment: Text.AlignRight
            text: parent.valueText
            color: parent.rowColor
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

    component CpuLegendButton: Item {
        id: btn
        property string seriesName: ""
        readonly property int graphRevision: cpuGraph._revision
        readonly property var history: {
            const _ = btn.graphRevision;
            return cpuGraph.history(seriesName);
        }
        readonly property bool seriesEnabled: {
            const _ = btn.graphRevision;
            return cpuGraph.isSeriesVisible(seriesName);
        }
        readonly property color clr: history ? history.color : "transparent"
        readonly property string lbl: history ? history.name : ""
        readonly property int val: {
            const _ = btn.graphRevision;
            return cpuGraph.currentValue(seriesName);
        }

        implicitHeight: 20

        Rectangle {
            anchors.fill: parent; anchors.topMargin: 2; anchors.bottomMargin: 2
            radius: 3
            color: btn.clr
            opacity: btn.seriesEnabled ? 1.0 : 0.5
            Behavior on opacity {
                NumberAnimation {
                    duration: Config.behaviour.animation.enabled ? Config.behaviour.animation.calc(0.12) : 0
                    easing.type: Easing.OutCubic
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: cpuGraph.toggleSeries(btn.seriesName)
        }

        Text {
            anchors.centerIn: parent
            horizontalAlignment: Text.AlignHCenter
            text: `${btn.lbl} (${btn.val}%)`
            font.pixelSize: 13
            color: Config.colors.base
        }
    }

    component CpuLegendDelegate: CpuLegendButton {
        required property int index

        Layout.fillWidth: true
        seriesName: root.cpuCoreNames()[index] || ""
    }

    component PartitionRow: StatTableRow {
        required property var modelData

        label: modelData.mount || ""
        valueText: `${modelData.usedGiB || 0} / ${modelData.totalGiB || 0} GiB`
        percent: modelData.percent !== undefined ? modelData.percent : -1
        percentColor: percent >= 90 ? Config.styling.critical : (percent >= 75 ? Config.styling.warning : Config.styling.text0)
    }
}
