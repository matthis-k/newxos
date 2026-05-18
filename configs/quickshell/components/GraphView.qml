import QtQuick
import QtCore
import Quickshell
import Quickshell.Io
import qs.services

Item {
    id: root

    implicitWidth: 400
    implicitHeight: 180

    // [{ name, value, color, visible, transform }]
    property var dataSets: []
    property real yMin: 0
    property real yMax: 100
    property int xWindowMs: 300000
    property int maxSamples: -1
    property bool active: true
    property string yLabelFormat: "%1"

    property bool samplingEnabled: true
    property int sampleIntervalMs: 1000
    property bool timestampEnabled: true

    property bool cacheEnabled: false
    property bool cacheLoadEnabled: true
    property bool cacheSaveEnabled: true
    property string cacheKey: ""

    // Optional function(leftName, rightName) -> negative/zero/positive.
    property var renderOrderCompare: null

    property var _histories: ({})
    property var _visibleOverrides: ({})
    property bool _cacheLoaded: false
    property int _revision: 0
    property int _sequence: 0

    function _cachePath() {
        return StandardPaths.writableLocation(StandardPaths.StateLocation) + "/graphs/" + root.cacheKey + ".json";
    }

    function _historyWindowMs() {
        return Math.max(root.xWindowMs, 1);
    }

    function _pointX(point, fallback) {
        return point.time !== undefined ? point.time : (point.x !== undefined ? point.x : fallback);
    }

    function _pointY(point) {
        return point.value !== undefined ? point.value : (point.y !== undefined ? point.y : 0);
    }

    function _resolveName(nameOrIndex) {
        if (typeof nameOrIndex === "number")
            return root.dataSetNames()[nameOrIndex] || "";
        return String(nameOrIndex || "");
    }

    function _dataSet(name) {
        for (let i = 0; i < root.dataSets.length; i++) {
            const item = root.dataSets[i];
            if (item && item.name === name)
                return item;
        }
        return null;
    }

    function _compareNames(left, right) {
        return root.renderOrderCompare ? root.renderOrderCompare(left, right) : String(left).localeCompare(String(right));
    }

    function _ensureHistory(item) {
        if (!item || !item.name)
            return null;

        const name = String(item.name);
        const existing = root._histories[name] || {};
        root._histories[name] = {
            name: name,
            color: item.color || existing.color || Config.colors.blue,
            visible: item.visible !== undefined ? item.visible : (existing.visible !== false),
            transform: item.transform || existing.transform || null,
            data: existing.data || []
        };
        return root._histories[name];
    }

    function _trim(data) {
        const maxAge = root.timestampEnabled ? Date.now() - root._historyWindowMs() : null;
        let result = root.timestampEnabled ? data.filter(p => p.time >= maxAge) : data.slice();
        const maxCount = root.maxSamples > 0 ? root.maxSamples : Math.max(1, Math.ceil(root.xWindowMs / root.sampleIntervalMs) + 1);
        if (result.length > maxCount)
            result = result.slice(result.length - maxCount);
        return result;
    }

    function sample() {
        if (!root.samplingEnabled)
            return;

        const now = Date.now();
        const next = Object.assign({}, root._histories);

        for (let i = 0; i < root.dataSets.length; i++) {
            const item = root.dataSets[i];
            const history = root._ensureHistory(item);
            if (!history || item.value === undefined || item.value === null)
                continue;

            const point = root.timestampEnabled
                ? { time: now, value: item.value }
                : { x: root._sequence, value: item.value };
            next[history.name] = Object.assign({}, history, { data: root._trim(history.data.concat([point])) });
        }

        root._sequence++;
        root._histories = next;
        root._revision++;
        canvas.requestPaint();
        root._saveCache();
    }

    function dataSetNames() {
        const names = {};
        for (let i = 0; i < root.dataSets.length; i++) {
            if (root.dataSets[i] && root.dataSets[i].name)
                names[String(root.dataSets[i].name)] = true;
        }
        for (const name in root._histories)
            names[name] = true;

        return Object.keys(names).sort((left, right) => String(left).localeCompare(String(right)));
    }

    function renderNames() {
        return root.dataSetNames().sort(root._compareNames);
    }

    function history(nameOrIndex) {
        const name = root._resolveName(nameOrIndex);
        return root._histories[name] || root._ensureHistory(root._dataSet(name));
    }

    function currentValue(nameOrIndex) {
        const item = root.history(nameOrIndex);
        const data = item ? item.data : [];
        return data && data.length > 0 ? Math.round(root._pointY(data[data.length - 1])) : 0;
    }

    function isSeriesVisible(nameOrIndex) {
        const name = root._resolveName(nameOrIndex);
        if (!name)
            return false;
        if (root._visibleOverrides[name] !== undefined)
            return root._visibleOverrides[name];

        const item = root._dataSet(name) || root._histories[name];
        return item ? item.visible !== false : false;
    }

    function toggleSeries(nameOrIndex) {
        const name = root._resolveName(nameOrIndex);
        if (!name)
            return;

        const next = Object.assign({}, root._visibleOverrides);
        next[name] = !root.isSeriesVisible(name);
        root._visibleOverrides = next;
        root._revision++;
        canvas.requestPaint();
    }

    function _loadCache() {
        if (!root.cacheEnabled || !root.cacheLoadEnabled || root.cacheKey === "") {
            root._cacheLoaded = true;
            return;
        }
        cacheLoader.exec({ command: ["sh", "-c", `cat "${root._cachePath()}" 2>/dev/null || echo '{}'`] });
    }

    function _applyCache(text) {
        try {
            const payload = JSON.parse(text || "{}");
            const loaded = payload.histories || {};
            const next = {};

            for (const name in loaded) {
                const item = loaded[name];
                next[name] = {
                    name: name,
                    color: item.color || Config.colors.blue,
                    visible: item.visible !== false,
                    data: root._trim(item.data || [])
                };
            }
            root._histories = next;
        } catch (e) {
            root._histories = {};
        }
        root._cacheLoaded = true;
        root._revision++;
        canvas.requestPaint();
    }

    function _saveCache() {
        if (!root.cacheEnabled || !root.cacheSaveEnabled || root.cacheKey === "" || !root._cacheLoaded)
            return;

        cacheSaver.exec({
            command: ["sh", "-c", `mkdir -p "$1" && printf '%s' "$2" > "$1/$3.json"`, "save", StandardPaths.writableLocation(StandardPaths.StateLocation) + "/graphs", JSON.stringify({ histories: root._histories }), root.cacheKey]
        });
    }

    Process {
        id: cacheLoader
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root._applyCache(text)
        }
    }

    Process {
        id: cacheSaver
    }

    Component.onCompleted: root._loadCache()
    onCacheKeyChanged: root._loadCache()
    onCacheEnabledChanged: root._loadCache()

    Canvas {
        id: canvas
        anchors.fill: parent
        anchors.margins: 4

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();

            const w = width;
            const h = height;
            const padTop = 8;
            const padBottom = 8;
            const padRight = 4;
            const now = Date.now();
            const windowStart = now - root._historyWindowMs();

            ctx.font = "10px sans-serif";
            const padLeft = ctx.measureText(root.yLabelFormat.arg(Math.round(root.yMax))).width + 8;
            const graphW = Math.max(1, w - padLeft - padRight);
            const graphH = Math.max(1, h - padTop - padBottom);
            const yRange = Math.max(1, root.yMax - root.yMin);

            ctx.fillStyle = Config.colors.surface0;
            ctx.fillRect(padLeft, padTop, graphW, graphH);

            ctx.strokeStyle = Config.colors.overlay0;
            ctx.lineWidth = 1;
            ctx.fillStyle = Config.styling.text0;
            ctx.textAlign = "right";
            ctx.textBaseline = "middle";

            for (let i = 0; i <= 5; i++) {
                const val = root.yMin + (yRange * i / 5);
                const y = padTop + graphH - ((val - root.yMin) / yRange) * graphH;
                ctx.beginPath();
                ctx.moveTo(padLeft, y);
                ctx.lineTo(w - padRight, y);
                ctx.stroke();
                ctx.fillText(root.yLabelFormat.arg(Math.round(val)), padLeft - 4, y);
            }

            const names = root.renderNames();
            for (let n = 0; n < names.length; n++) {
                const item = root.history(names[n]);
                const data = item ? root._trim(item.data || []) : [];
                if (!item || !root.isSeriesVisible(names[n]) || data.length === 0)
                    continue;

                const xMin = root.timestampEnabled ? windowStart : root._pointX(data[0], 0);
                const xMax = root.timestampEnabled ? now : root._pointX(data[data.length - 1], data.length - 1);
                const xRange = Math.max(1, xMax - xMin);

                ctx.strokeStyle = item.color || Config.colors.blue;
                ctx.lineWidth = 1.6;
                ctx.beginPath();

                let drawn = 0;
                let lastX = 0;
                let lastY = 0;

                for (let i = 0; i < data.length; i++) {
                    const point = data[i];
                    let xValue = root._pointX(point, i);
                    let yValue = root._pointY(point);

                    if (root.timestampEnabled && xValue < windowStart)
                        continue;

                    if (item.transform) {
                        const transformed = item.transform(xValue, yValue, point);
                        if (transformed && transformed.visible === false)
                            continue;
                        if (transformed && transformed.x !== undefined)
                            xValue = transformed.x;
                        if (transformed && transformed.y !== undefined)
                            yValue = transformed.y;
                    }

                    const x = padLeft + ((xValue - xMin) / xRange) * graphW;
                    const y = padTop + graphH - ((Math.max(root.yMin, Math.min(root.yMax, yValue)) - root.yMin) / yRange) * graphH;
                    drawn === 0 ? ctx.moveTo(x, y) : ctx.lineTo(x, y);
                    lastX = x;
                    lastY = y;
                    drawn++;
                }

                if (drawn === 1)
                    ctx.arc(lastX, lastY, 2, 0, Math.PI * 2);
                ctx.stroke();
            }
        }
    }

    Timer {
        interval: Math.max(100, root.sampleIntervalMs)
        running: root.active && root.samplingEnabled && root._cacheLoaded
        repeat: true
        triggeredOnStart: true
        onTriggered: root.sample()
    }

    Timer {
        interval: 1000
        running: root.active
        repeat: true
        onTriggered: canvas.requestPaint()
    }

    onDataSetsChanged: canvas.requestPaint()
    onActiveChanged: canvas.requestPaint()
}
