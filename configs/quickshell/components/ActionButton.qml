import QtQuick
import qs.services

InteractiveButton {
    id: root

    property bool active: false
    property bool fillOnHover: true
    property bool indicatorOnHover: false

    property color accentColor: Config.styling.activeIndicator
    property color backgroundColor: "transparent"
    property color borderColor: "transparent"
    property int borderWidth: 0

    property int highlightSide: ActiveIndicator.Side.Top
    property int highlightAnimationMode: ActiveIndicator.AnimationMode.GrowAll
    property real highlightThickness: (highlightSide === ActiveIndicator.Side.Top || highlightSide === ActiveIndicator.Side.Bottom) ? height * 0.1 : width * 0.1
    property real fillOpacity: Config.behaviour.hoverBgOpacity
    property int scaleAnimationDuration: Config.behaviour.animation.calc(0.1)

    padding: 0
    leftPadding: 0
    rightPadding: 0
    topPadding: 0
    bottomPadding: 0

    Rectangle {
        anchors.fill: parent
        z: -1
        clip: true
        color: root.backgroundColor
        border.width: root.borderWidth
        border.color: root.borderColor
        radius: Config.styling.radius

        ActiveIndicator {
            anchors.fill: parent
            side: root.highlightSide
            animationMode: root.highlightAnimationMode
            thickness: root.highlightThickness
            color: root.accentColor
            bgOpacity: root.fillOpacity
            bgActive: (root.fillOnHover && root.hovered) || root.active
            active: root.active || (root.indicatorOnHover && root.hovered)
        }
    }
}
