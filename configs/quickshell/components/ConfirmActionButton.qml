import QtQuick

ActionButton {
    id: root

    property bool confirming: false
    property int confirmTimeoutMs: 1600

    signal confirmed

    onClicked: {
        if (confirming) {
            confirming = false;
            confirmTimer.stop();
            confirmed();
            return;
        }

        confirming = true;
        confirmTimer.restart();
    }

    Timer {
        id: confirmTimer
        interval: root.confirmTimeoutMs
        onTriggered: root.confirming = false
    }
}
