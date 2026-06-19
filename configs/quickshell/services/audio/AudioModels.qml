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

    function findStreamTarget(stream, linkGroups) {
        if (!stream) return null;
        for (const link of linkGroups || []) {
            if (link.source && link.target && link.source.id === stream.id)
                return link.target;
        }
        return null;
    }

    function buildSinksWithStreams(sinks, streams, defaultSink, linkGroups) {
        const result = [];
        const sorted = (sinks || []).slice();
        sorted.sort(function(a, b) {
            const aDefault = defaultSink && a.id === defaultSink.id;
            const bDefault = defaultSink && b.id === defaultSink.id;
            if (aDefault !== bDefault) return aDefault ? -1 : 1;
            return (a.description || a.name || "").localeCompare(b.description || b.name || "");
        });

        for (const sink of sorted) {
            const attachedStreams = (streams || []).filter(stream => root.isStreamConnectedTo(stream, sink, linkGroups));
            const isDefault = defaultSink && sink.id === defaultSink.id;
            if (attachedStreams.length > 0 || isDefault)
                result.push({ node: sink, streams: attachedStreams });
        }
        return result;
    }

    function buildSourcesWithStreams(sources, streams, defaultSource, linkGroups) {
        const result = [];
        const sorted = (sources || []).slice();
        sorted.sort(function(a, b) {
            const aDefault = defaultSource && a.id === defaultSource.id;
            const bDefault = defaultSource && b.id === defaultSource.id;
            if (aDefault !== bDefault) return aDefault ? -1 : 1;
            return (a.description || a.name || "").localeCompare(b.description || b.name || "");
        });

        for (const source of sorted) {
            const attachedStreams = (streams || []).filter(stream => root.isStreamConnectedTo(stream, source, linkGroups));
            const isDefault = defaultSource && source.id === defaultSource.id;
            if (attachedStreams.length > 0 || isDefault)
                result.push({ node: source, streams: attachedStreams });
        }
        return result;
    }
}
