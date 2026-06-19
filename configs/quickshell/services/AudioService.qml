pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import "audio"

Singleton {
    id: root

    readonly property var backend: Pipewire

    readonly property PipewireQuery pipewireQuery: PipewireQuery {}
    readonly property AudioNodeUtils nodeUtils: AudioNodeUtils {}
    readonly property AudioModels audioModels: AudioModels {}
    readonly property AudioPresentation audioPresentation: AudioPresentation {}
    readonly property AudioCommands audioCommands: AudioCommands {
        onMoveStreamFinished: function(success, message) {
            root.finishOperation(success, message);
            root._revision++;
        }
    }
    readonly property AudioDeviceNormalizer normalizer: AudioDeviceNormalizer {
        nodeUtils: root.nodeUtils
        pipewireQuery: root.pipewireQuery
        defaultSink: root.defaultSink
        defaultSource: root.defaultSource
    }

    readonly property bool available: true

    readonly property var defaultSink: Pipewire.defaultAudioSink
    readonly property var defaultSource: Pipewire.defaultAudioSource

    readonly property var allNodes: root.audioModels.collectNodes(Pipewire.nodes.values || [])
    readonly property var linkGroups: Pipewire.linkGroups.values || []
    readonly property var outputs: root.audioModels.audioSinks(root.allNodes)
    readonly property var inputs: root.audioModels.audioSources(root.allNodes)
    readonly property var outputStreams: root.audioModels.outputStreams(root.allNodes)
    readonly property var inputStreams: root.audioModels.inputStreams(root.allNodes)
    readonly property var sinksWithStreams: root.audioModels.buildSinksWithStreams(root.outputs, root.outputStreams, root.defaultSink, root.linkGroups)
    readonly property var sourcesWithStreams: root.audioModels.buildSourcesWithStreams(root.inputs, root.inputStreams, root.defaultSource, root.linkGroups)

    readonly property real outputVolume: defaultSink ? root.nodeUtils.volumePercent(defaultSink) : 0
    readonly property bool outputMuted: defaultSink ? root.nodeUtils.isMuted(defaultSink) : false
    readonly property string outputDeviceName: defaultSink ? root.nodeUtils.nodeName(defaultSink, "Output") : "No output"

    readonly property real inputVolume: defaultSource ? root.nodeUtils.volumePercent(defaultSource) : 0
    readonly property bool inputMuted: defaultSource ? root.nodeUtils.isMuted(defaultSource) : false
    readonly property string inputDeviceName: defaultSource ? root.nodeUtils.nodeName(defaultSource, "Input") : "No input"

    property var _revision: 0
    property string currentOperationKind: ""
    property string currentOperationTarget: ""
    property bool currentOperationRunning: false
    property string currentOperationLastError: ""

    readonly property var operation: ({
        kind: currentOperationKind,
        target: currentOperationTarget,
        running: currentOperationRunning,
        lastError: currentOperationLastError
    })
    readonly property bool busy: currentOperationRunning

    function beginOperation(kind, target) {
        currentOperationKind = kind || "";
        currentOperationTarget = target || "";
        currentOperationRunning = true;
        currentOperationLastError = "";
    }

    function finishOperation(success, message) {
        currentOperationRunning = false;
        currentOperationLastError = success ? "" : (message || `${currentOperationKind || "operation"} failed`);
    }

    readonly property string outputIconName: defaultSink ? root.nodeUtils.volumeIconName(defaultSink, false) : "audio-volume-muted-symbolic"
    readonly property color outputIconColor: outputMuted ? Config.styling.critical : (outputVolume === 0 ? Config.styling.warning : Config.styling.text0)
    readonly property string inputIconName: defaultSource ? root.nodeUtils.volumeIconName(defaultSource, true) : "audio-input-microphone-symbolic"
    readonly property color inputIconColor: inputMuted ? Config.styling.critical : (inputVolume === 0 ? Config.styling.warning : Config.styling.text0)

    readonly property string label: "Audio"
    readonly property string statusText: defaultSink ? `${root.nodeUtils.nodeName(defaultSink, "Output")} ${root.outputVolume}%` : "No output"

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

    function executePayload(payload) {
        if (!payload) return false;
        switch (payload.op) {
        case "setVolume": return root.setVolumeById(payload.nodeId, Number(payload.value || 0));
        case "adjustVolume": return root.setVolumeById(payload.nodeId, root.volumePercentById(payload.nodeId) + Number(payload.delta || 0));
        case "setMuted": return root.setMutedById(payload.nodeId, !!payload.muted);
        case "toggleMute": return root.toggleMuteById(payload.nodeId);
        case "setDefaultOutput": root.setDefaultOutput(payload.nodeId); return true;
        case "setDefaultInput": root.setDefaultInput(payload.nodeId); return true;
        default: return false;
        }
    }

    function volumePercentById(id) {
        const node = root.pipewireQuery.rawNodeById(id);
        return node ? root.nodeUtils.volumePercent(node) : null;
    }

    function setVolumeById(id, percent) {
        const node = root.pipewireQuery.rawNodeById(id);
        if (!node) return false;
        root.beginOperation("set-volume", String(id));
        root.nodeUtils.setVolume(node, percent);
        root._revision++;
        root.finishOperation(true, "");
        return true;
    }

    function setMutedById(id, value) {
        const node = root.pipewireQuery.rawNodeById(id);
        if (!node) return false;
        root.beginOperation("toggle", String(id));
        root.nodeUtils.setMuted(node, value);
        root._revision++;
        root.finishOperation(true, "");
        return true;
    }

    function toggleMuteById(id) {
        const node = root.pipewireQuery.rawNodeById(id);
        if (!node) return false;
        root.beginOperation("toggle", String(id));
        root.nodeUtils.toggleMute(node);
        root._revision++;
        root.finishOperation(true, "");
        return true;
    }

    function setVolume(node, value) {
        root.beginOperation("set-volume", node ? String(node.id) : "");
        if (!root.audioCommands.setVolume(node, value)) {
            root.finishOperation(false, "Audio node not found");
            return;
        }
        root._revision++;
        root.finishOperation(true, "");
    }

    function toggleMute(node) {
        root.beginOperation("toggle", node ? String(node.id) : "");
        if (!root.audioCommands.toggleMute(node)) {
            root.finishOperation(false, "Audio node not found");
            return;
        }
        root._revision++;
        root.finishOperation(true, "");
    }

    function setDefaultSink(sink) {
        root.beginOperation("set-profile", sink ? String(sink.id) : "");
        if (!root.audioCommands.setDefaultSink(sink)) {
            root.finishOperation(false, "Audio output not found");
            return;
        }
        root._revision++;
        root.finishOperation(true, "");
    }

    function setDefaultSource(source) {
        root.beginOperation("set-profile", source ? String(source.id) : "");
        if (!root.audioCommands.setDefaultSource(source)) {
            root.finishOperation(false, "Audio input not found");
            return;
        }
        root._revision++;
        root.finishOperation(true, "");
    }

    function setOutputVolume(value) {
        root.setVolume(defaultSink, value);
    }

    function adjustOutputVolume(delta) {
        root.beginOperation("set-volume", defaultSink ? String(defaultSink.id) : "");
        root.nodeUtils.adjustVolume(defaultSink, delta);
        root._revision++;
        root.finishOperation(true, "");
    }

    function toggleOutputMute() {
        root.toggleMute(defaultSink);
    }

    function setInputVolume(value) {
        root.setVolume(defaultSource, value);
    }

    function adjustInputVolume(delta) {
        root.beginOperation("set-volume", defaultSource ? String(defaultSource.id) : "");
        root.nodeUtils.adjustVolume(defaultSource, delta);
        root._revision++;
        root.finishOperation(true, "");
    }

    function toggleInputMute() {
        root.toggleMute(defaultSource);
    }

    function setDefaultOutput(id) {
        root.beginOperation("set-profile", String(id || ""));
        for (const node of Pipewire.nodes.values || []) {
            if (node.id === id || String(node.id) === String(id)) {
                root.setDefaultSink(node);
                return;
            }
        }
        root.finishOperation(false, "Audio output not found");
    }

    function setDefaultInput(id) {
        root.beginOperation("set-profile", String(id || ""));
        for (const node of Pipewire.nodes.values || []) {
            if (node.id === id || String(node.id) === String(id)) {
                root.setDefaultSource(node);
                return;
            }
        }
        root.finishOperation(false, "Audio input not found");
    }

    function moveStreamTo(stream, sink) {
        const streamNode = typeof stream === "object" ? stream : root.pipewireQuery.rawNodeById(stream);
        const targetNode = typeof sink === "object" ? sink : root.pipewireQuery.rawNodeById(sink);
        root.beginOperation("move-stream", `${streamNode ? streamNode.id : stream}:${targetNode ? targetNode.id : sink}`);
        if (!streamNode || !targetNode) {
            root.finishOperation(false, "Audio stream or target not found");
            return;
        }
        root.audioCommands.moveStreamTo(streamNode, targetNode);
    }

    readonly property var outputVolumeControl: defaultSink ? root.normalizer.volumeControl(defaultSink) : null
    readonly property var inputVolumeControl: defaultSource ? root.normalizer.volumeControl(defaultSource) : null

    function outputDeviceEntries() { return root.normalizer.outputDeviceEntries(); }
    function inputDeviceEntries() { return root.normalizer.inputDeviceEntries(); }
    function streamEntriesForOutput(outputId) { return root.normalizer.streamEntriesForOutput(outputId); }

    function findStreamTarget(stream) { return root.audioModels.findStreamTarget(stream, root.linkGroups); }
    function isStreamConnectedTo(stream, targetNode) { return root.audioModels.isStreamConnectedTo(stream, targetNode, root.linkGroups); }
    function streamName(stream) { return root.audioPresentation.streamName(stream); }
    function streamIconName(stream) { return root.audioPresentation.streamIconName(stream); }
    function humanName(node) { return root.audioPresentation.humanName(node); }
    function volumeIconName(node, inputNode) { return root.nodeUtils.volumeIconName(node, inputNode); }
    function isMuted(node) { return root.nodeUtils.isMuted(node); }
    function volumePercent(node) { return root.nodeUtils.volumePercent(node); }

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
