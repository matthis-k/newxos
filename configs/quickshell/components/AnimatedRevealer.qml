import QtQuick
import qs.services

Item {
    id: root

    property bool revealed: false
    property int duration: Config.behaviour.animation.calc(0.2)
    property alias content: contentContainer.children

    implicitWidth: contentContainer.implicitWidth
    implicitHeight: revealed ? contentContainer.implicitHeight : 0

    Behavior on implicitHeight {
        NumberAnimation {
            duration: root.duration
            easing.type: Easing.InOutCubic
        }
    }

    clip: true

    Item {
        id: contentContainer
        width: parent.width
        height: childrenRect.height
    }
}
