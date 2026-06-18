import QtQml
import Quickshell.Services.Pipewire

QtObject {
    id: root

    function audioNodes(type) {
        const out = [];
        for (const node of Pipewire.nodes.values || []) {
            if ((node.type & type) === type)
                out.push(node);
        }
        return out;
    }

    function rawNodeById(id) {
        for (const node of Pipewire.nodes.values || []) {
            if (node.id === id || String(node.id) === String(id))
                return node;
        }
        return null;
    }

    function isStreamConnectedTo(stream, targetNode) {
        if (!stream || !targetNode) return false;
        for (const link of Pipewire.linkGroups.values || []) {
            if (link.source && link.target && link.source.id === stream.id && link.target.id === targetNode.id)
                return true;
        }
        return false;
    }

    function streamsForSink(sink) {
        const type = PwNodeType.AudioOutStream;
        return root.audioNodes(type).filter(function(stream) {
            return root.isStreamConnectedTo(stream, sink);
        });
    }

    function streamsForSource(source) {
        const type = PwNodeType.AudioInStream;
        return root.audioNodes(type).filter(function(stream) {
            return root.isStreamConnectedTo(stream, source);
        });
    }

    function findStreamTarget(stream) {
        if (!stream) return null;
        for (const link of Pipewire.linkGroups.values || []) {
            if (link.source && link.target && link.source.id === stream.id)
                return link.target;
        }
        return null;
    }
}
