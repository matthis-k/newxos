import QtQml

QtObject {
    id: root

    function nodeName(node, fallback) {
        if (!node) return fallback || "";
        return node.nickname || node.description || node.name || fallback || "";
    }

    function volumePercent(node) {
        return node && node.audio ? Math.round((node.audio.volume || 0) * 100) : 0;
    }

    function setVolume(node, percent) {
        if (!node || !node.audio) return false;
        node.audio.volume = Math.max(0, Math.min(1.5, percent / 100));
        return true;
    }

    function adjustVolume(node, delta) {
        if (!node || !node.audio) return;
        const current = root.volumePercent(node);
        root.setVolume(node, current + delta);
    }

    function isMuted(node) {
        return !!(node && node.audio && node.audio.muted);
    }

    function setMuted(node, value) {
        if (!node || !node.audio) return false;
        node.audio.muted = value;
        return true;
    }

    function toggleMute(node) {
        if (!node || !node.audio) return false;
        node.audio.muted = !node.audio.muted;
        return true;
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
}
