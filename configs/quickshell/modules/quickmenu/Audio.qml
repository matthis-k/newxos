import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

import qs.services
import qs.components

DashboardPage {
    id: root

    title: "Audio"
    subtitle: root.defaultSink
        ? `${root.humanName(root.defaultSink)} • ${root.volumePercent(root.defaultSink)}% default output`
        : "No default output device"

    readonly property int contentWidth: width > 0 ? width : 360
    readonly property int itemSpacing: 3
    readonly property int rowHeight: 40
    readonly property int actionHeight: 28
    readonly property int iconSlotWidth: 28
    readonly property int iconSize: 20
    readonly property int itemIconSize: 22
    readonly property int itemTextSize: 14
    readonly property int itemSubtextSize: 12
    readonly property int iconTextGap: 10
    readonly property int horizontalPadding: 8
    readonly property int verticalPadding: 4
    readonly property int sliderHeight: 24
    readonly property int sliderWidth: 100

    property bool popupOpen: false

    readonly property var allNodes: collectNodes()
    readonly property var audioSinks: allNodes.filter(n => (n.type & PwNodeType.AudioSink) === PwNodeType.AudioSink)
    readonly property var audioSources: allNodes.filter(n => (n.type & PwNodeType.AudioSource) === PwNodeType.AudioSource)
    readonly property var outputStreams: allNodes.filter(n => (n.type & PwNodeType.AudioOutStream) === PwNodeType.AudioOutStream)
    readonly property var inputStreams: allNodes.filter(n => (n.type & PwNodeType.AudioInStream) === PwNodeType.AudioInStream)

    readonly property var defaultSink: Pipewire.defaultAudioSink
    readonly property var defaultSource: Pipewire.defaultAudioSource

    readonly property var sinksWithStreams: buildSinksWithStreams()
    readonly property var sourcesWithStreams: buildSourcesWithStreams()

    PwObjectTracker {
        objects: [defaultSink, defaultSource].concat(audioSinks).concat(audioSources).concat(outputStreams).concat(inputStreams)
    }

    function collectNodes() {
        const items = [];
        for (const node of Pipewire.nodes.values || [])
            items.push(node);
        return items;
    }

    function nodeKey(node) {
        return node ? `${node.id}` : "";
    }

    function buildSinksWithStreams() {
        const result = [];
        const sinks = audioSinks.slice();

        sinks.sort((a, b) => {
            const aDefault = defaultSink && a.id === defaultSink.id;
            const bDefault = defaultSink && b.id === defaultSink.id;
            if (aDefault !== bDefault) return aDefault ? -1 : 1;
            return (a.description || a.name || "").localeCompare(b.description || b.name || "");
        });

        for (const sink of sinks) {
            const streams = outputStreams.filter(s => isStreamConnectedTo(s, sink));
            const isDefault = defaultSink && sink.id === defaultSink.id;
            if (streams.length > 0 || isDefault)
                result.push({ node: sink, streams: streams });
        }
        return result;
    }

    function buildSourcesWithStreams() {
        const result = [];
        const sources = audioSources.slice();

        sources.sort((a, b) => {
            const aDefault = defaultSource && a.id === defaultSource.id;
            const bDefault = defaultSource && b.id === defaultSource.id;
            if (aDefault !== bDefault) return aDefault ? -1 : 1;
            return (a.description || a.name || "").localeCompare(b.description || b.name || "");
        });

        for (const source of sources) {
            const streams = inputStreams.filter(s => isStreamConnectedTo(s, source));
            const isDefault = defaultSource && source.id === defaultSource.id;
            if (streams.length > 0 || isDefault)
                result.push({ node: source, streams: streams });
        }
        return result;
    }

    function isStreamConnectedTo(stream, targetNode) {
        if (!stream || !targetNode) return false;
        for (const link of Pipewire.linkGroups.values || []) {
            if (link.source && link.target && link.source.id === stream.id && link.target.id === targetNode.id)
                return true;
        }
        return false;
    }

    function findStreamTarget(stream) {
        if (!stream) return null;
        for (const link of Pipewire.linkGroups.values || []) {
            if (link.source && link.target && link.source.id === stream.id)
                return link.target;
        }
        return null;
    }

    function humanName(node) {
        if (!node) return "Unknown";
        if (node.nickname) return node.nickname;
        if (node.description) return node.description;
        return node.name || "Unknown";
    }

    function streamName(stream) {
        if (!stream) return "Unknown";
        const props = stream.properties || {};
        const mediaName = props["media.name"];
        const appName = props["application.name"];
        if (mediaName && appName) return `${mediaName} — ${appName}`;
        if (mediaName) return mediaName;
        if (appName) return appName;
        return stream.description || stream.name || "Unknown stream";
    }

    function streamIconName(stream) {
        if (!stream) return "audio-x-generic-symbolic";
        const props = stream.properties || {};
        return props["application.icon-name"] || "audio-x-generic-symbolic";
    }

    function volumePercent(node) {
        if (!node || !node.audio) return 0;
        return Math.round((node.audio.volume || 0) * 100);
    }

    function setVolume(node, percent) {
        if (!node || !node.audio) return;
        node.audio.volume = Math.max(0, Math.min(1.5, percent / 100));
    }

    function toggleMute(node) {
        if (!node || !node.audio) return;
        node.audio.muted = !node.audio.muted;
    }

    function isMuted(node) {
        return node && node.audio && node.audio.muted;
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

    function setDefaultSink(sink) {
        if (!sink) return;
        Pipewire.preferredDefaultAudioSink = sink;
    }

    function setDefaultSource(source) {
        if (!source) return;
        Pipewire.preferredDefaultAudioSource = source;
    }

    function moveStreamTo(stream, sink) {
        if (!stream || !sink) return;
        const proc = moveProcess.createObject(root, {});
        proc.command = ["pw-cli", "move-stream", `${stream.id}`, `${sink.id}`];
        proc.running = true;
        proc.onExited.connect(function() { proc.destroy(); });
    }


    component VolumeSlider: Item {
        id: sliderRoot

        required property var node
        readonly property int vol: root.volumePercent(node)

        implicitWidth: root.sliderWidth + root.iconSlotWidth + root.iconTextGap + 42
        implicitHeight: root.sliderHeight

        AudioLevelSlider {
            anchors.fill: parent
            iconName: root.volumeIconName(sliderRoot.node, false)
            iconColor: root.isMuted(sliderRoot.node) ? Config.styling.critical : Config.styling.text0
            valueText: `${sliderRoot.vol}%`
            from: 0
            to: 150
            value: sliderRoot.vol
            stepSize: 1
            enabled: !!sliderRoot.node
            accentColor: root.isMuted(sliderRoot.node) ? Config.styling.critical : Config.colors.blue
            iconSize: root.iconSize
            onIconClicked: root.toggleMute(sliderRoot.node)
            onValueModified: (value) => root.setVolume(sliderRoot.node, value)
        }
    }

    component StreamRow: Item {
        id: streamRow

        required property var stream
        required property var sinkEntry

        readonly property var target: root.findStreamTarget(streamRow.stream)
        readonly property bool isDefaultTarget: root.defaultSink && target && root.defaultSink.id === target.id

        implicitWidth: root.contentWidth
        implicitHeight: rowContent.implicitHeight + root.verticalPadding * 2

        Rectangle {
            anchors.fill: parent
            color: Config.styling.bg2
            opacity: 0.5
        }

        ColumnLayout {
            id: rowContent
            anchors.fill: parent
            anchors.margins: root.horizontalPadding
            spacing: root.itemSpacing

            RowLayout {
                Layout.fillWidth: true
                spacing: root.iconTextGap

                Icon {
                    Layout.preferredWidth: root.itemIconSize
                    Layout.preferredHeight: root.itemIconSize
                    iconName: root.streamIconName(streamRow.stream)
                    color: Config.styling.text0
                    implicitSize: root.itemIconSize
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        Layout.fillWidth: true
                        text: root.streamName(streamRow.stream)
                        color: Config.styling.text0
                        font.pixelSize: root.itemTextSize
                        font.bold: true
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        text: streamRow.isDefaultTarget ? "Default output" : (root.target ? root.humanName(root.target) : "No output")
                        color: Config.styling.text2
                        font.pixelSize: root.itemSubtextSize
                        elide: Text.ElideRight
                    }
                }
            }

            VolumeSlider {
                Layout.fillWidth: true
                node: streamRow.stream
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: root.itemSpacing

                Text {
                    text: "Output:"
                    color: Config.styling.text1
                    font.pixelSize: 12
                }

                ComboBox {
                    id: outputSelector
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.actionHeight
                    implicitHeight: root.actionHeight
                    model: outputSelector.displayModel
                    currentIndex: findCurrentIndex()

                    popup.onOpened: root.popupOpen = true
                    popup.onClosed: root.popupOpen = false

                    popup.background: Rectangle {
                        color: Config.styling.bg2
                        border.width: 1
                        border.color: Config.styling.bg5
                        radius: Config.styling.radius
                    }

                    property var displayModel: root.audioSinks.map(s => ({
                        node: s,
                        label: root.humanName(s),
                        isDefault: root.defaultSink && s.id === root.defaultSink.id
                    }))

                    textRole: ""
                    displayText: outputSelector.displayModel.length > 0 && outputSelector.currentIndex >= 0
                        ? outputSelector.displayModel[outputSelector.currentIndex].label
                        : "Select output"

                    contentItem: Text {
                        leftPadding: root.horizontalPadding
                        rightPadding: root.horizontalPadding
                        verticalAlignment: Text.AlignVCenter
                        text: outputSelector.displayText
                        color: Config.styling.text0
                        font.pixelSize: 12
                        elide: Text.ElideRight
                    }

                    delegate: ItemDelegate {
                        required property int index
                        width: outputSelector.width
                        highlighted: outputSelector.highlightedIndex === index

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: root.horizontalPadding
                            anchors.rightMargin: root.horizontalPadding
                            spacing: root.iconTextGap

                            Icon {
                                Layout.preferredWidth: root.iconSize
                                Layout.preferredHeight: root.iconSize
                                iconName: outputSelector.displayModel[index].isDefault
                                    ? "audio-card-symbolic"
                                    : "audio-speakers-symbolic"
                                color: outputSelector.displayModel[index].isDefault
                                    ? Config.colors.blue
                                    : Config.styling.text0
                                implicitSize: root.iconSize
                            }

                            Text {
                                Layout.fillWidth: true
                                text: outputSelector.displayModel[index].label
                                color: Config.styling.text0
                                font.pixelSize: 12
                                elide: Text.ElideRight
                            }

                            Text {
                                visible: outputSelector.displayModel[index].isDefault
                                text: "Default"
                                color: Config.colors.blue
                                font.pixelSize: 11
                                font.bold: true
                            }
                        }

                        background: Rectangle {
                            color: outputSelector.highlightedIndex === index
                                ? Config.styling.bg4
                                : "transparent"
                        }
                    }

                    background: Rectangle {
                        color: Config.styling.bg3
                        radius: Config.styling.radius
                        border.width: 1
                        border.color: Config.styling.bg5
                    }

                    function findCurrentIndex() {
                        const target = streamRow.target;
                        if (!target) return 0;
                        for (let i = 0; i < outputSelector.displayModel.length; i++) {
                            if (outputSelector.displayModel[i].node.id === target.id)
                                return i;
                        }
                        return 0;
                    }

                    onActivated: function(index) {
                        if (index >= 0 && index < outputSelector.displayModel.length) {
                            const targetSink = outputSelector.displayModel[index].node;
                            root.moveStreamTo(streamRow.stream, targetSink);
                        }
                    }
                }
            }
        }
    }

    component DeviceRow: Item {
        id: deviceRow

        required property var node
        required property var streams

        readonly property bool isDefault: (root.defaultSink && node.id === root.defaultSink.id) || (root.defaultSource && node.id === root.defaultSource.id)
        readonly property bool inputNode: (deviceRow.node.type & PwNodeType.AudioSource) === PwNodeType.AudioSource

        implicitWidth: root.contentWidth
        implicitHeight: card.implicitHeight

        AudioDeviceCard {
            id: card
            anchors.fill: parent
            title: root.humanName(deviceRow.node)
            iconName: root.volumeIconName(deviceRow.node, deviceRow.inputNode)
            iconColor: root.isMuted(deviceRow.node) ? Config.styling.critical : Config.styling.text0
            valueText: `${root.volumePercent(deviceRow.node)}%`
            from: 0
            to: 150
            value: root.volumePercent(deviceRow.node)
            stepSize: 1
            iconEnabled: !!deviceRow.node
            sliderEnabled: !!deviceRow.node && !root.isMuted(deviceRow.node)
            accentColor: root.isMuted(deviceRow.node) ? Config.styling.critical : Config.colors.blue
            showDefaultBadge: deviceRow.isDefault
            onIconClicked: root.toggleMute(deviceRow.node)
            onValueModified: (value) => root.setVolume(deviceRow.node, value)
        }
    }

    DashboardSection {
        Layout.fillWidth: true
        Layout.fillHeight: true
        title: "Output devices"

        DashboardScrollArea {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentSpacing: root.itemSpacing

            Repeater {
                model: root.sinksWithStreams

                delegate: DeviceRow {
                    required property var modelData
                    Layout.fillWidth: true
                    node: modelData.node
                    streams: modelData.streams
                }
            }

            Text {
                visible: root.sinksWithStreams.length === 0
                text: "No output devices found"
                color: Config.styling.text2
                font.pixelSize: 12
            }
        }
    }

    DashboardSection {
        Layout.fillWidth: true
        Layout.fillHeight: true
        title: "Input devices"

        DashboardScrollArea {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentSpacing: root.itemSpacing

            Repeater {
                model: root.sourcesWithStreams

                delegate: DeviceRow {
                    required property var modelData
                    Layout.fillWidth: true
                    node: modelData.node
                    streams: modelData.streams
                }
            }

            Text {
                visible: root.sourcesWithStreams.length === 0
                text: "No input devices found"
                color: Config.styling.text2
                font.pixelSize: 12
            }
        }
    }

    Component {
        id: moveProcess
        Process {}
    }
}
