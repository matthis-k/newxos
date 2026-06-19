import QtQml
import Quickshell.Services.Pipewire
import qs.services

QtObject {
    id: root

    property var nodeUtils: null
    property var pipewireQuery: null
    property var defaultSink: null
    property var defaultSource: null

    function normalizeDevice(node, isInput) {
        const muted = root.nodeUtils.isMuted(node);
        const vol = root.nodeUtils.volumePercent(node);
        const isDefault = isInput
            ? (root.defaultSource && node.id === root.defaultSource.id)
            : (root.defaultSink && node.id === root.defaultSink.id);

        return {
            id: String(node.id),
            name: root.nodeUtils.nodeName(node, isInput ? "Input" : "Output"),
            kind: isInput ? "input" : "output",
            default: isDefault,
            volume: vol,
            muted: muted,
            iconName: root.nodeUtils.volumeIconName(node, isInput),
            iconColor: muted ? root.errorColor() : root.textColor(),
            statusText: isDefault ? "Default" : `${vol}%`,
            control: {
                kind: "slider",
                target: "audio",
                nodeId: node.id,
                from: 0,
                to: 150,
                step: 5,
                value: vol
            },
            switchActions: {
                toggle: {
                    id: "toggle",
                    title: "Toggle",
                    state: null,
                    payload: { service: "audio", op: "toggleMute", nodeId: String(node.id) }
                },
                on: {
                    id: "on",
                    title: "On",
                    state: true,
                    payload: { service: "audio", op: "setMuted", nodeId: String(node.id), muted: true }
                },
                off: {
                    id: "off",
                    title: "Off",
                    state: false,
                    payload: { service: "audio", op: "setMuted", nodeId: String(node.id), muted: false }
                }
            }
        };
    }

    function normalizeStream(stream) {
        const props = stream.properties || {};
        const mediaName = props["media.name"];
        const appName = props["application.name"];
        const name = mediaName || appName || root.nodeUtils.nodeName(stream, "Stream");
        const vol = root.nodeUtils.volumePercent(stream);
        const muted = root.nodeUtils.isMuted(stream);

        return {
            id: String(stream.id),
            name: name,
            kind: "stream",
            default: false,
            volume: vol,
            muted: muted,
            iconName: props["application.icon-name"] || "audio-x-generic-symbolic",
            iconColor: muted ? root.errorColor() : root.textColor(),
            statusText: `${vol}%`,
            control: {
                kind: "slider",
                target: "audio",
                nodeId: stream.id,
                from: 0,
                to: 150,
                step: 5,
                value: vol
            },
            switchActions: {
                toggle: {
                    id: "toggle",
                    title: "Toggle",
                    state: null,
                    payload: { service: "audio", op: "toggleMute", nodeId: String(stream.id) }
                }
            }
        };
    }

    function outputDeviceEntries() {
        const type = PwNodeType;
        const sinks = root.pipewireQuery.audioNodes(type.AudioSink).slice();
        sinks.sort(function(a, b) {
            const aDefault = root.defaultSink && a.id === root.defaultSink.id;
            const bDefault = root.defaultSink && b.id === root.defaultSink.id;
            if (aDefault !== bDefault) return aDefault ? -1 : 1;
            return root.nodeUtils.nodeName(a).localeCompare(root.nodeUtils.nodeName(b));
        });
        return sinks.map(function(sink) { return root.normalizeDevice(sink, false); });
    }

    function inputDeviceEntries() {
        const type = PwNodeType;
        const sources = root.pipewireQuery.audioNodes(type.AudioSource).slice();
        sources.sort(function(a, b) {
            const aDefault = root.defaultSource && a.id === root.defaultSource.id;
            const bDefault = root.defaultSource && b.id === root.defaultSource.id;
            if (aDefault !== bDefault) return aDefault ? -1 : 1;
            return root.nodeUtils.nodeName(a).localeCompare(root.nodeUtils.nodeName(b));
        });
        return sources.map(function(source) { return root.normalizeDevice(source, true); });
    }

    function streamEntriesForOutput(outputId) {
        const sink = root.pipewireQuery.rawNodeById(outputId);
        if (!sink) return [];
        const streams = root.pipewireQuery.streamsForSink(sink);
        return streams.map(function(stream) { return root.normalizeStream(stream); });
    }

    function errorColor() { return Config.styling.critical; }
    function textColor() { return Config.styling.text0; }

    function volumeControl(node) {
        if (!node) return null;
        return {
            kind: "slider",
            target: "pipewire",
            nodeId: node.id,
            from: 0,
            to: 150,
            step: 5,
            value: root.nodeUtils.volumePercent(node)
        };
    }
}
