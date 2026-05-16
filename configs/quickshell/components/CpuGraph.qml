import QtQuick
import QtQuick.Layouts
import qs.services

Item {
    id: root
    implicitHeight: 270
    implicitWidth: 400

    property var seriesList: []
    property var seriesColors: []
    property real maxValue: 100
    property int graphMaxSamples: 60
    property bool active: false

    property var _seriesEnabled: []
    property int _tick: 0

    function toggleSeries(index) {
        if (index < 0 || index >= _seriesEnabled.length)
            return;
        const newEnabled = _seriesEnabled.slice();
        newEnabled[index] = !newEnabled[index];
        _seriesEnabled = newEnabled;
        canvas.requestPaint();
    }

    function seriesLabel(seriesIndex) {
        return seriesIndex === 0 ? "avg" : `core${seriesIndex}`;
    }

    function seriesColor(seriesIndex) {
        return root.seriesColors[seriesIndex % root.seriesColors.length];
    }

    Canvas {
        id: canvas
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            bottom: legend.top
            margins: 4
        }

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();

            const w = canvas.width;
            const h = canvas.height;
            const padTop = 8;
            const padBottom = 8;
            const padRight = 4;

            ctx.font = "10px sans-serif";
            const labelWidth = ctx.measureText("100%").width + 8;
            const padLeft = labelWidth;

            const graphH = h - padTop - padBottom;
            const graphW = w - padLeft - padRight;

            ctx.fillStyle = Config.colors.surface0;
            ctx.fillRect(padLeft, padTop, graphW, graphH);

            ctx.strokeStyle = Config.colors.overlay0;
            ctx.lineWidth = 1;
            ctx.fillStyle = Config.styling.text0;
            ctx.textAlign = "right";
            ctx.textBaseline = "middle";

            for (let pct = 0; pct <= 100; pct += 25) {
                const y = padTop + graphH - (pct / root.maxValue) * graphH;
                ctx.beginPath();
                ctx.moveTo(padLeft, y);
                ctx.lineTo(w - padRight, y);
                ctx.stroke();
                ctx.fillText(`${pct}%`, padLeft - 4, y);
            }

            if (!root.seriesList || root.seriesList.length === 0)
                return;

            const stepX = graphW / (root.graphMaxSamples - 1);
            const drawOrder = [];
            for (let s = 1; s < root.seriesList.length; s++)
                drawOrder.push(s);
            drawOrder.push(0);

            for (let d = 0; d < drawOrder.length; d++) {
                const s = drawOrder[d];
                if (root._seriesEnabled[s] === false)
                    continue;

                const data = root.seriesList[s];
                if (!data || data.length < 2)
                    continue;

                const color = seriesColor(s);
                const len = data.length;
                const startX = padLeft + (root.graphMaxSamples - len) * stepX;

                ctx.strokeStyle = color;
                ctx.lineWidth = 1.5;
                ctx.beginPath();

                for (let i = 0; i < len; i++) {
                    const x = startX + i * stepX;
                    const y = padTop + graphH - (Math.min(data[i], root.maxValue) / root.maxValue) * graphH;
                    i === 0 ? ctx.moveTo(x, y) : ctx.lineTo(x, y);
                }

                ctx.stroke();
            }
        }
    }

    ColumnLayout {
        id: legend
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        spacing: 2

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Item { Layout.fillWidth: true }

            LegendButton {
                Layout.preferredWidth: 100
                Layout.alignment: Qt.AlignHCenter
                seriesIndex: 0
                seriesEnabled: root._seriesEnabled[0] !== false
                seriesColor: root.seriesColor(0)
                labelText: root.seriesLabel(0)
                currentValue: {
                    const _ = root._tick;
                    const data = root.seriesList[0];
                    return data && data.length > 0 ? Math.round(data[data.length - 1]) : 0;
                }
                onClicked: root.toggleSeries(0)
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
                model: Math.max(0, root.seriesList.length - 1)

                LegendButton {
                    Layout.fillWidth: true
                    seriesIndex: index + 1
                    seriesEnabled: root._seriesEnabled[index + 1] !== false
                    seriesColor: root.seriesColor(index + 1)
                    labelText: root.seriesLabel(index + 1)
                    currentValue: {
                        const _ = root._tick;
                        const data = root.seriesList[index + 1];
                        return data && data.length > 0 ? Math.round(data[data.length - 1]) : 0;
                    }
                    onClicked: root.toggleSeries(index + 1)
                }
            }
        }
    }

    Timer {
        id: repaintTimer
        interval: 1000
        running: root.active
        repeat: true
        onTriggered: {
            root._tick++;
            canvas.requestPaint();
        }
    }

    onActiveChanged: canvas.requestPaint()

    onSeriesListChanged: {
        const newEnabled = [];
        for (let i = 0; i < seriesList.length; i++)
            newEnabled[i] = i === 0;
        _seriesEnabled = newEnabled;
        canvas.requestPaint();
    }

    component LegendButton: Item {
        id: btn
        property int seriesIndex: 0
        property bool seriesEnabled: true
        property color seriesColor: "transparent"
        property string labelText: ""
        property int currentValue: 0
        signal clicked

        implicitHeight: 20

        Rectangle {
            anchors {
                fill: parent
                topMargin: 2
                bottomMargin: 2
            }
            radius: 3
            color: btn.seriesColor
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
            text: `${btn.labelText} (${btn.currentValue}%)`
            font.pixelSize: 13
            color: Config.colors.base
        }
    }
}
