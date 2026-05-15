pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool available: false
    property int currentValue: 0
    property int maxValue: 100

    readonly property int percent: available && maxValue > 0 ? Math.round((currentValue / maxValue) * 100) : 0
    readonly property string iconName: {
        if (!available)
            return "display-brightness-off-symbolic";
        if (percent <= 0)
            return "display-brightness-off-symbolic";
        if (percent < 34)
            return "display-brightness-low-symbolic";
        if (percent < 67)
            return "display-brightness-medium-symbolic";
        return "display-brightness-high-symbolic";
    }

    function applyProbe(text) {
        const parts = (text || "").trim().split(/\s+/);
        if (parts.length < 2) {
            available = false;
            return;
        }

        const current = parseInt(parts[0], 10);
        const max = parseInt(parts[1], 10);
        if (isNaN(current) || isNaN(max) || max <= 0) {
            available = false;
            return;
        }

        currentValue = current;
        maxValue = max;
        available = true;
    }

    function refresh() {
        probe.exec({
            command: [
                "sh",
                "-c",
                "cur=$(brightnessctl -q -c backlight g 2>/dev/null) || exit 1; max=$(brightnessctl -q -c backlight m 2>/dev/null) || exit 1; printf '%s %s\\n' \"$cur\" \"$max\""
            ]
        });
    }

    function setPercent(targetPercent) {
        if (!available)
            return;

        const clamped = Math.max(0, Math.min(100, Math.round(targetPercent)));
        setter.exec({
            command: ["brightnessctl", "-q", "-n2", "-c", "backlight", "set", `${clamped}%`]
        });
        refreshDelay.restart();
    }

    Process {
        id: probe
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.applyProbe(text)
        }
        function onExited(exitCode) {
            if (exitCode !== 0)
                root.available = false;
        }
    }

    Process {
        id: setter
        function onExited(exitCode) {
            refreshDelay.restart();
        }
    }

    Timer {
        id: pollTimer
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Timer {
        id: refreshDelay
        interval: 200
        onTriggered: root.refresh()
    }
}
