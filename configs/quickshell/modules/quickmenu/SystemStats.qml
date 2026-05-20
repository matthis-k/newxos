pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import qs.services
import qs.services as Services
import qs.components

DashboardPage {
    id: root

    title: "System stats"
    scrollable: true

    readonly property var cpuCoreColors: [Config.colors.green, Config.colors.yellow, Config.colors.red, Config.colors.maroon, Config.colors.peach, Config.colors.mauve, Config.colors.pink, Config.colors.flamingo, Config.colors.rosewater]
    readonly property color ramColor: Config.colors.mauve
    readonly property color swapColor: Config.colors.blue

    function cpuGraphSeries() {
        const _ = Services.Stats.graphRevision;
        return Services.Stats.calculateCpuGraphSeries().map(series => Object.assign({}, series, {
                color: series.name === "avg" ? Config.colors.blue : root.cpuCoreColors[parseInt(String(series.name).replace("core", "")) % root.cpuCoreColors.length],
                lineWidth: series.name === "avg" ? 2.5 : 1.2
            }));
    }

    readonly property int _coreCount: {
        const _ = Services.Stats.graphRevision;
        return Services.Stats.cpuCorePercents.length;
    }

    function cpuCoreNameAt(index) {
        return `core${index}`;
    }

    function anyCoresVisible() {
        for (let i = 0; i < root._coreCount; i++) {
            if (cpuGraph.isSeriesVisible(root.cpuCoreNameAt(i)))
                return true;
        }
        return false;
    }

    function toggleAllCores() {
        const show = !root.anyCoresVisible();
        for (let i = 0; i < root._coreCount; i++) {
            const name = root.cpuCoreNameAt(i);
            if (cpuGraph.isSeriesVisible(name) !== show)
                cpuGraph.toggleSeries(name);
        }
    }

    function memoryGraphSeries() {
        const _ = Services.Stats.graphRevision;
        return Services.Stats.calculateMemoryGraphSeries().map(series => Object.assign({}, series, {
                color: series.name === "RAM" ? root.ramColor : root.swapColor
            }));
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
                xWindow: 120000
                xMarkerInterval: 60000
                xMarkerLabel: (x, view) => x < view.maxX ? qsTr("%1m").arg(Math.round((view.maxX - x) / 60000)) : ""
                graphs: root.cpuGraphSeries()
                Layout.fillWidth: true
                Layout.preferredHeight: 180
                Layout.minimumHeight: 140
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Item {
                    Layout.fillWidth: true
                }
                CpuLegendButton {
                    Layout.preferredWidth: 100
                    Layout.alignment: Qt.AlignHCenter
                    seriesName: "avg"
                    onClicked: cpuGraph.toggleSeries("avg")
                }
                CpuLegendButton {
                    Layout.preferredWidth: 100
                    Layout.alignment: Qt.AlignHCenter
                    lbl: "cores"
                    seriesEnabled: root.anyCoresVisible()
                    color: Config.colors.overlay2
                    onClicked: root.toggleAllCores()
                }
                Item {
                    Layout.fillWidth: true
                }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 4
                rowSpacing: 2
                columnSpacing: 8
                uniformCellWidths: true

                Repeater {
                    model: root._coreCount
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
                xWindow: 300000
                xMarkerInterval: 60000
                xMarkerLabel: (x, view) => x < view.maxX ? qsTr("%1m").arg(Math.round((view.maxX - x) / 60000)) : ""
                graphs: root.memoryGraphSeries()
                Layout.fillWidth: true
                Layout.preferredHeight: 160
                Layout.minimumHeight: 120
            }

            StatTableHeader {}

            StatTableRow {
                label: "RAM"
                valueText: `${Services.Stats.memoryUsedMiB} / ${Services.Stats.memoryTotalMiB} MiB`
                percent: Services.Stats.memoryPercent
                rowColor: root.ramColor
                percentColor: root.ramColor
            }

            StatTableRow {
                label: "Swap"
                valueText: Services.Stats.swapTotalMiB > 0 ? `${Services.Stats.swapUsedMiB} / ${Services.Stats.swapTotalMiB} MiB` : "Disabled"
                percent: Services.Stats.swapTotalMiB > 0 ? Services.Stats.swapPercent : -1
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
                model: Services.Stats.diskPartitions

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
            value: Services.Stats.formatRate(Services.Stats.rxBytesPerSecond)
            Layout.fillWidth: true
        }

        InfoRow {
            iconName: "go-up-symbolic"
            label: "Upload"
            value: Services.Stats.formatRate(Services.Stats.txBytesPerSecond)
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
        property string lbl: seriesName
        property bool seriesEnabled: cpuGraph.isSeriesVisible(seriesName)
        property color color: {
            const s = cpuGraph.series(seriesName);
            return s ? s.color : Config.colors.surface1;
        }
        signal clicked

        implicitHeight: 20

        Rectangle {
            anchors.fill: parent
            anchors.topMargin: 2
            anchors.bottomMargin: 2
            radius: 3
            color: btn.color
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
            onClicked: btn.clicked()
        }

        Text {
            anchors.centerIn: parent
            horizontalAlignment: Text.AlignHCenter
            text: btn.lbl
            font.pixelSize: 13
            color: Config.colors.base
        }
    }

    component CpuLegendDelegate: CpuLegendButton {
        required property int index

        Layout.fillWidth: true
        seriesName: root.cpuCoreNameAt(index)
    }

    component PartitionRow: StatTableRow {
        required property var modelData

        label: modelData.mount || ""
        valueText: `${modelData.usedGiB || 0} / ${modelData.totalGiB || 0} GiB`
        percent: modelData.percent !== undefined ? modelData.percent : -1
        percentColor: percent >= 90 ? Config.styling.critical : (percent >= 75 ? Config.styling.warning : Config.styling.text0)
    }
}
