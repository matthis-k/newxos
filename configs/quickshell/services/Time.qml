pragma Singleton
import Quickshell
import QtQuick

Singleton {
    id: root
    readonly property string time: {
        Qt.formatDateTime(clock.date, "HH:mm:ss");
    }

    function formatted(format: string): string {
        return Qt.formatDateTime(clock.date, format);
    }

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }
}
