import QtQml
import Quickshell
import Quickshell.Services.Pipewire

QtObject {
    id: root

    signal moveStreamFinished(bool success, string message)

    function setDefaultSink(sink) {
        if (!sink) return false;
        Pipewire.preferredDefaultAudioSink = sink;
        return true;
    }

    function setDefaultSource(source) {
        if (!source) return false;
        Pipewire.preferredDefaultAudioSource = source;
        return true;
    }

    function toggleMute(node) {
        if (!node?.audio) return false;
        node.audio.muted = !node.audio.muted;
        return true;
    }

    function setVolume(node, value) {
        if (!node?.audio) return false;
        node.audio.volume = Math.max(0, Math.min(1.5, value / 100));
        return true;
    }

    function moveStreamTo(stream, sink) {
        if (!stream || !sink) return false;
        const proc = Qt.createQmlObject("import Quickshell.Io; Process {}", root);
        proc.command = ["pw-cli", "move-stream", String(stream.id), String(sink.id)];
        proc.running = true;
        proc.onExited.connect(function(exitCode) {
            root.moveStreamFinished(exitCode === 0, exitCode === 0 ? "" : `move stream failed (${exitCode})`);
            proc.destroy();
        });
        return true;
    }
}
