import QtQuick
import QtQuick.Layouts
import qs.services

Item {
    id: root
    implicitHeight: 180
    implicitWidth: 400

    property var seriesList: []
    property var seriesColors: []
    property real maxValue: 100
    property int graphMaxSamples: 60
    property bool active: false

    property var _labels: []
    property var _displayModel: []
    property int _tick: 0

    readonly property int _legendHeight: 16

    Canvas {
        id: canvas
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            bottom: legend.top
            rightMargin: 4
            topMargin: 2
            bottomMargin: 2
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

            ctx.strokeStyle = Config.styling.bg4;
            ctx.lineWidth = 0.5;
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
                const data = root.seriesList[s];
                if (!data || data.length < 2)
                    continue;

                const color = root.seriesColors[s % root.seriesColors.length];
                const len = data.length;
                const startX = padLeft + (root.graphMaxSamples - len) * stepX;

                ctx.strokeStyle = color;
                ctx.lineWidth = 1.5;
                ctx.beginPath();

                for (let i = 0; i < len; i++) {
                    const x = startX + i * stepX;
                    const y = padTop + graphH - (Math.min(data[i], root.maxValue) / root.maxValue) * graphH;

                    if (i === 0)
                        ctx.moveTo(x, y);
                    else
                        ctx.lineTo(x, y);
                }

                ctx.stroke();
            }
        }
    }

    GridLayout {
        id: legend
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            margins: 4
        }
        columns: 5
        rowSpacing: 2
        columnSpacing: 8
        uniformCellWidths: true

        Repeater {
            model: root._displayModel.length

            Text {
                horizontalAlignment: Text.AlignHCenter
                text: {
                    const _ = root._tick;
                    const item = root._displayModel[index];
                    if (!item)
                        return "";
                    const current = item.length > 0 ? Math.round(item[item.length - 1]) : 0;
                    return `${root._labels[index]} (${current}%)`;
                }
                font.pixelSize: 10
                color: {
                    if (!root._displayModel[index]) return "transparent";
                    const seriesIdx = index > 5 ? index - 1 : index;
                    return root.seriesColors[seriesIdx % root.seriesColors.length];
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

    onActiveChanged: {
        if (active)
            canvas.requestPaint();
    }

    onSeriesListChanged: {
        const newModel = [];
        const newLabels = [];

        newModel[0] = seriesList[0];
        newLabels[0] = "avg";

        for (let i = 1; i < seriesList.length; i++) {
            const idx = i + (i > 4 ? 1 : 0);
            newModel[idx] = seriesList[i];
            newLabels[idx] = `core${i}`;
        }

        for (let k = 0; k < newModel.length; k++) {
            if (newModel[k] === undefined) {
                newModel[k] = null;
                newLabels[k] = "";
            }
        }

        _displayModel = newModel;
        _labels = newLabels;

        if (root.active)
            canvas.requestPaint();
    }
}
