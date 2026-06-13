import QtQuick
import QtQuick.Layouts
import qs.animations as Animations

Item {
    id: root

    property real targetHeight: 0
    property real maximumHeight: targetHeight
    property real animatedHeight: targetHeight
    default property alias content: contentHost.data

    visible: targetHeight > 0 || animatedHeight > 0
    implicitHeight: animatedHeight
    clip: true
    Layout.fillWidth: true
    Layout.preferredHeight: animatedHeight
    Layout.maximumHeight: maximumHeight

    Animations.LayoutBehavior on animatedHeight {
    }

    Item {
        id: contentHost

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: root.targetHeight
    }
}
