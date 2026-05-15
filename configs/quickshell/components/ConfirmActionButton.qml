import QtQuick

ActionButton {
    id: control

    signal confirmed

    property bool confirming: false
    property int confirmTimeoutMs: 1600

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
        interval: control.confirmTimeoutMs
        onTriggered: control.confirming = false
    }
}
