import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs.services

StatusIcon {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real vol: sink?.audio?.volume || 0.0
    readonly property bool muted: sink?.audio?.muted || false

    iconName: {
        if (muted || (vol ?? 0) <= 0.001)
            return "audio-volume-muted-symbolic";
        const p = (vol ?? 0);
        if (p < 0.34)
            return "audio-volume-low-symbolic";
        if (p < 0.67)
            return "audio-volume-medium-symbolic";
        return "audio-volume-high-symbolic";
    }

    color: {
        if (muted)
            return Config.styling.critical;
        if ((vol ?? 0) === 0.0)
            return Config.styling.warning;
        return Config.styling.text0;
    }

    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }
    quickmenuName: "audio"
}
