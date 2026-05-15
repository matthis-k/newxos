import QtQuick
import QtQuick.Controls

import qs.services

Switch {
    id: root

    property color accentColor: Config.styling.primaryAccent
    property color knobColor: Config.styling.textOnAccent

    implicitWidth: 38
    implicitHeight: 22
    hoverEnabled: true
    spacing: 0
    padding: 0
    text: ""

    indicator: Item {
        implicitWidth: root.implicitWidth
        implicitHeight: root.implicitHeight

        Rectangle {
            anchors.fill: parent
            anchors.margins: -2
            radius: height / 2
            color: Config.colorWithOpacity(root.accentColor, 0.18)
            opacity: root.hovered && root.enabled ? 1 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: Config.behaviour.animation.enabled
                        ? Config.behaviour.animation.calc(0.12)
                        : 0
                    easing.type: Easing.OutCubic
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: !root.enabled
                ? Config.styling.bg4
                : root.checked
                    ? root.accentColor
                    : Config.styling.bg5

            Behavior on color {
                ColorAnimation {
                    duration: Config.behaviour.animation.enabled
                        ? Config.behaviour.animation.calc(0.12)
                        : 0
                    easing.type: Easing.OutCubic
                }
            }
        }

        Rectangle {
            width: parent.height - 4
            height: parent.height - 4
            x: 2 + root.visualPosition * (parent.width - width - 4)
            y: 2
            radius: width / 2
            color: root.knobColor

            Behavior on x {
                NumberAnimation {
                    duration: Config.behaviour.animation.enabled
                        ? Config.behaviour.animation.calc(0.14)
                        : 0
                    easing.type: Easing.OutCubic
                }
            }
        }
    }

    contentItem: Item {
        implicitWidth: 0
        implicitHeight: 0
    }
}
