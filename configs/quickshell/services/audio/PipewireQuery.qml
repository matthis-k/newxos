import QtQml
import Quickshell.Services.Pipewire

QtObject {
    function rawNodeById(id) {
        for (const node of Pipewire.nodes.values || []) {
            if (node.id === id || String(node.id) === String(id))
                return node;
        }
        return null;
    }
}
