import QtQuick
import QtQuick.Layouts
import qs.services

Item {
    id: root
    implicitHeight: 200
    implicitWidth: 400

    property var seriesList: []
    property var seriesColors: []
    property var seriesVisible: []
    property real maxValue: 100
    property int graphMaxSamples: 60
    property bool active: false
    property string yLabelFormat: "%1%"

    function _extractValue(item) {
        if (item === null || item === undefined)
            return 0;
        if (typeof item === "object" && "value" in item)
            return item.value;
        return item;
    }

    Canvas {
        id: canvas
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            bottom: parent.bottom
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
            const labelWidth = ctx.measureText(yLabelFormat.arg(100)).width + 8;
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
                ctx.fillText(yLabelFormat.arg(pct), padLeft - 4, y);
            }

            if (!root.seriesList || root.seriesList.length === 0)
                return;

            const stepX = graphW / (root.graphMaxSamples - 1);

            for (let s = 0; s < root.seriesList.length; s++) {
                if (root.seriesVisible[s] === false)
                    continue;

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
                    const val = root._extractValue(data[i]);
                    const y = padTop + graphH - (Math.min(val, root.maxValue) / root.maxValue) * graphH;
                    i === 0 ? ctx.moveTo(x, y) : ctx.lineTo(x, y);
                }

                ctx.stroke();
            }
        }
    }

    Timer {
        id: repaintTimer
        interval: 1000
        running: root.active
        repeat: true
        onTriggered: canvas.requestPaint()
    }

    onActiveChanged: canvas.requestPaint()
    onSeriesListChanged: canvas.requestPaint()
}
