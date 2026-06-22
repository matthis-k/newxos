import QtQml
import Quickshell.Services.Pipewire

QtObject {
    id: root

    function collectNodes(pipewireNodes) {
        const items = [];
        for (const node of pipewireNodes || [])
            items.push(node);
        return items;
    }

    function audioSinks(nodes) {
        return (nodes || []).filter(node => (node.type & PwNodeType.AudioSink) === PwNodeType.AudioSink);
    }

    function audioSources(nodes) {
        return (nodes || []).filter(node => (node.type & PwNodeType.AudioSource) === PwNodeType.AudioSource);
    }

    function outputStreams(nodes) {
        return (nodes || []).filter(node => (node.type & PwNodeType.AudioOutStream) === PwNodeType.AudioOutStream);
    }

    function inputStreams(nodes) {
        return (nodes || []).filter(node => (node.type & PwNodeType.AudioInStream) === PwNodeType.AudioInStream);
    }

    function isStreamConnectedTo(stream, targetNode, linkGroups) {
        if (!stream || !targetNode) return false;
        for (const link of linkGroups || []) {
            if (link.source && link.target && link.source.id === stream.id && link.target.id === targetNode.id)
                return true;
        }
        return false;
    }

}
