pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    readonly property var backend: Pipewire

    readonly property bool available: true

    readonly property var defaultSink: Pipewire.defaultAudioSink
    readonly property var defaultSource: Pipewire.defaultAudioSource

    readonly property var outputs: audioNodes(PwNodeType.AudioSink)
    readonly property var inputs: audioNodes(PwNodeType.AudioSource)
    readonly property var outputStreams: audioNodes(PwNodeType.AudioOutStream)
    readonly property var inputStreams: audioNodes(PwNodeType.AudioInStream)

    readonly property real outputVolume: defaultSink ? volumePercent(defaultSink) : 0
    readonly property bool outputMuted: defaultSink ? isMuted(defaultSink) : false
    readonly property string outputDeviceName: defaultSink ? nodeName(defaultSink, "Output") : "No output"

    readonly property real inputVolume: defaultSource ? volumePercent(defaultSource) : 0
    readonly property bool inputMuted: defaultSource ? isMuted(defaultSource) : false
    readonly property string inputDeviceName: defaultSource ? nodeName(defaultSource, "Input") : "No input"

    property var _revision: 0

    readonly property string outputIconName: defaultSink ? volumeIconName(defaultSink, false) : "audio-volume-muted-symbolic"
    readonly property color outputIconColor: outputMuted ? Config.styling.critical : (outputVolume === 0 ? Config.styling.warning : Config.styling.text0)
    readonly property string inputIconName: defaultSource ? volumeIconName(defaultSource, true) : "audio-input-microphone-symbolic"
    readonly property color inputIconColor: inputMuted ? Config.styling.critical : (inputVolume === 0 ? Config.styling.warning : Config.styling.text0)

    readonly property string label: "Audio"
    readonly property string statusText: defaultSink ? `${nodeName(defaultSink, "Output")} ${outputVolume}%` : "No output"

    readonly property var presentation: {
        return {
            icon: root.outputIconName,
            color: root.outputIconColor,
            label: root.label,
            status: root.statusText,
            outputDeviceName: root.outputDeviceName,
            outputVolume: root.outputVolume,
            outputMuted: root.outputMuted,
            inputDeviceName: root.inputDeviceName,
            inputVolume: root.inputVolume,
            inputMuted: root.inputMuted
        };
    }

    readonly property var outputPresentation: {
        return {
            icon: root.outputIconName,
            color: root.outputIconColor,
            deviceName: root.outputDeviceName,
            volume: root.outputVolume,
            muted: root.outputMuted,
            control: root.outputVolumeControl
        };
    }

    readonly property var inputPresentation: {
        return {
            icon: root.inputIconName,
            color: root.inputIconColor,
            deviceName: root.inputDeviceName,
            volume: root.inputVolume,
            muted: root.inputMuted,
            control: root.inputVolumeControl
        };
    }

    function audioNodes(type) {
        const out = [];
        for (const node of Pipewire.nodes.values || []) {
            if ((node.type & type) === type)
                out.push(node);
        }
        return out;
    }

    function nodeName(node, fallback) {
        if (!node) return fallback || "";
        return node.nickname || node.description || node.name || fallback || "";
    }

    function volumePercent(node) {
        return node && node.audio ? Math.round((node.audio.volume || 0) * 100) : 0;
    }

    function setVolume(node, percent) {
        if (!node || !node.audio) return;
        node.audio.volume = Math.max(0, Math.min(1.5, percent / 100));
        root._revision++;
    }

    function volumePercentById(id) {
        const node = rawNodeById(id);
        return node ? volumePercent(node) : null;
    }

    function setVolumeById(id, percent) {
        const node = rawNodeById(id);
        if (!node) return false;
        setVolume(node, percent);
        return true;
    }

    function setMutedById(id, value) {
        const node = rawNodeById(id);
        if (!node) return false;
        setMuted(node, value);
        return true;
    }

    function toggleMuteById(id) {
        const node = rawNodeById(id);
        if (!node) return false;
        toggleMute(node);
        return true;
    }

    function executePayload(payload) {
        if (!payload) return false;
        switch (payload.op) {
        case "setVolume": return setVolumeById(payload.nodeId, Number(payload.value || 0));
        case "adjustVolume": return setVolumeById(payload.nodeId, volumePercentById(payload.nodeId) + Number(payload.delta || 0));
        case "setMuted": return setMutedById(payload.nodeId, !!payload.muted);
        case "toggleMute": return toggleMuteById(payload.nodeId);
        case "setDefaultOutput": setDefaultOutput(payload.nodeId); return true;
        case "setDefaultInput": setDefaultInput(payload.nodeId); return true;
        default: return false;
        }
    }

    function adjustVolume(node, delta) {
        if (!node || !node.audio) return;
        const current = volumePercent(node);
        setVolume(node, current + delta);
    }

    function isMuted(node) {
        return !!(node && node.audio && node.audio.muted);
    }

    function setMuted(node, value) {
        if (!node || !node.audio) return;
        node.audio.muted = value;
        root._revision++;
    }

    function toggleMute(node) {
        if (!node || !node.audio) return;
        node.audio.muted = !node.audio.muted;
        root._revision++;
    }

    function volumeIconName(node, inputNode) {
        if (!node || !node.audio)
            return inputNode ? "audio-input-microphone-symbolic" : "audio-volume-muted-symbolic";
        if (node.audio.muted)
            return inputNode ? "microphone-sensitivity-muted-symbolic" : "audio-volume-muted-symbolic";
        const vol = node.audio.volume || 0;
        if (inputNode)
            return vol <= 0.001 ? "microphone-sensitivity-muted-symbolic" : "audio-input-microphone-symbolic";
        if (vol <= 0.001)
            return "audio-volume-muted-symbolic";
        if (vol < 0.34)
            return "audio-volume-low-symbolic";
        if (vol < 0.67)
            return "audio-volume-medium-symbolic";
        return "audio-volume-high-symbolic";
    }

    function setOutputVolume(value) {
        setVolume(defaultSink, value);
    }

    function adjustOutputVolume(delta) {
        adjustVolume(defaultSink, delta);
    }

    function toggleOutputMute() {
        toggleMute(defaultSink);
    }

    function setInputVolume(value) {
        setVolume(defaultSource, value);
    }

    function adjustInputVolume(delta) {
        adjustVolume(defaultSource, delta);
    }

    function toggleInputMute() {
        toggleMute(defaultSource);
    }

    function setDefaultOutput(id) {
        for (const node of Pipewire.nodes.values || []) {
            if (node.id === id || String(node.id) === String(id)) {
                Pipewire.preferredDefaultAudioSink = node;
                root._revision++;
                return;
            }
        }
    }

    function setDefaultInput(id) {
        for (const node of Pipewire.nodes.values || []) {
            if (node.id === id || String(node.id) === String(id)) {
                Pipewire.preferredDefaultAudioSource = node;
                root._revision++;
                return;
            }
        }
    }

    function moveStreamTo(streamId, targetNodeId) {
        const streamNode = rawNodeById(streamId);
        const targetNode = rawNodeById(targetNodeId);
        if (!streamNode || !targetNode) return;
        const proc = Qt.createQmlObject("import Quickshell.Io; Process {}", root);
        proc.command = ["pw-cli", "move-stream", String(streamNode.id), String(targetNode.id)];
        proc.running = true;
        proc.onExited.connect(function() { proc.destroy(); });
    }

    function rawNodeById(id) {
        for (const node of Pipewire.nodes.values || []) {
            if (node.id === id || String(node.id) === String(id))
                return node;
        }
        return null;
    }

    readonly property var outputVolumeControl: defaultSink ? {
        kind: "slider",
        target: "pipewire",
        nodeId: defaultSink.id,
        from: 0,
        to: 150,
        step: 5,
        value: volumePercent(defaultSink)
    } : null

    readonly property var inputVolumeControl: defaultSource ? {
        kind: "slider",
        target: "pipewire",
        nodeId: defaultSource.id,
        from: 0,
        to: 150,
        step: 5,
        value: volumePercent(defaultSource)
    } : null

    function outputDeviceEntries() {
        const sinks = audioNodes(PwNodeType.AudioSink).slice();
        sinks.sort((a, b) => {
            const aDefault = defaultSink && a.id === defaultSink.id;
            const bDefault = defaultSink && b.id === defaultSink.id;
            if (aDefault !== bDefault) return aDefault ? -1 : 1;
            return nodeName(a).localeCompare(nodeName(b));
        });

        return sinks.map(sink => normalizeDevice(sink, false));
    }

    function inputDeviceEntries() {
        const sources = audioNodes(PwNodeType.AudioSource).slice();
        sources.sort((a, b) => {
            const aDefault = defaultSource && a.id === defaultSource.id;
            const bDefault = defaultSource && b.id === defaultSource.id;
            if (aDefault !== bDefault) return aDefault ? -1 : 1;
            return nodeName(a).localeCompare(nodeName(b));
        });

        return sources.map(source => normalizeDevice(source, true));
    }

    function normalizeDevice(node, isInput) {
        const muted = isMuted(node);
        const vol = volumePercent(node);
        const isDefault = isInput
            ? (defaultSource && node.id === defaultSource.id)
            : (defaultSink && node.id === defaultSink.id);

        return {
            id: String(node.id),
            name: nodeName(node, isInput ? "Input" : "Output"),
            kind: isInput ? "input" : "output",
            default: isDefault,
            volume: vol,
            muted: muted,
            iconName: volumeIconName(node, isInput),
            iconColor: muted ? Config.styling.critical : Config.styling.text0,
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

    function streamEntriesForOutput(outputId) {
        const sink = rawNodeById(outputId);
        if (!sink) return [];

        const streams = audioNodes(PwNodeType.AudioOutStream).filter(stream => {
            for (const link of Pipewire.linkGroups.values || []) {
                if (link.source && link.target && link.source.id === stream.id && link.target.id === sink.id)
                    return true;
            }
            return false;
        });

        return streams.map(stream => normalizeStream(stream));
    }

    function normalizeStream(stream) {
        const props = stream.properties || {};
        const mediaName = props["media.name"];
        const appName = props["application.name"];
        const name = mediaName || appName || nodeName(stream, "Stream");
        const vol = volumePercent(stream);
        const muted = isMuted(stream);

        return {
            id: String(stream.id),
            name: name,
            kind: "stream",
            default: false,
            volume: vol,
            muted: muted,
            iconName: props["application.icon-name"] || "audio-x-generic-symbolic",
            iconColor: muted ? Config.styling.critical : Config.styling.text0,
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

    Connections {
        target: Pipewire
        function onDefaultAudioSinkChanged() { root._revision++; }
        function onDefaultAudioSourceChanged() { root._revision++; }
    }

    Connections {
        target: Pipewire.nodes
        function onValuesChanged() { root._revision++; }
    }

    Connections {
        target: Pipewire.linkGroups
        function onValuesChanged() { root._revision++; }
    }
}
