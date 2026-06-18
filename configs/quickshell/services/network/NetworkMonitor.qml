import QtQuick
import QtQml
import Quickshell.Io

QtObject {
    id: root

    signal refreshRequested()

    property int debounceInterval: 300
    property int restartInterval: 2000
    property int initDelay: 100

    function start() {
        initTimer.start();
    }

    function restart() {
        monitorProcess.exec({
            command: ["nmcli", "monitor"]
        });
    }

    Timer {
        id: initTimer
        interval: root.initDelay
        onTriggered: {
            root.refreshRequested();
            monitorProcess.exec({
                command: ["nmcli", "monitor"]
            });
        }
    }

    Timer {
        id: monitorDebounce
        interval: root.debounceInterval
        onTriggered: root.refreshRequested()
    }

    Timer {
        id: monitorRestartTimer
        interval: root.restartInterval
        onTriggered: {
            monitorProcess.exec({
                command: ["nmcli", "monitor"]
            });
        }
    }

    Process {
        id: monitorProcess
        stdout: SplitParser {
            onRead: monitorDebounce.restart()
        }
        function onExited(exitCode, exitStatus) {
            monitorRestartTimer.start();
        }
    }
}
