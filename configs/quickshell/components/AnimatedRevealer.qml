import QtQuick
import qs.animations as Animations
import qs.services

Item {
    id: root

    property bool revealed: false
    property int duration: Config.motion.medium
    property alias content: contentContainer.children

    implicitWidth: contentContainer.implicitWidth
    implicitHeight: revealed ? contentContainer.implicitHeight : 0

    Animations.LayoutBehavior on implicitHeight {
        duration: root.duration
    }

    clip: true

    Item {
        id: contentContainer
        width: parent.width
        height: childrenRect.height
    }
}
