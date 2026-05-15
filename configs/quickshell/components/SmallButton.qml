import QtQuick
import qs.services

ActionButton {
    id: root

    implicitHeight: 28
    backgroundColor: Config.styling.bg3
    accentColor: Config.styling.activeIndicator
    highlightSide: ActiveIndicator.Side.Left
    highlightAnimationMode: ActiveIndicator.AnimationMode.GrowAlong
    highlightThickness: 3
    indicatorOnHover: true
    scaleTarget: null
    flat: true

    contentItem: Item {
        implicitWidth: label.implicitWidth + 16
        implicitHeight: root.implicitHeight

        Text {
            id: label
            anchors.centerIn: parent
            text: root.text
            color: Config.styling.text0
            font.pixelSize: 13
            font.bold: true
        }
    }
}
