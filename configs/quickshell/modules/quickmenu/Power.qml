import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.services
import qs.components

Item {
    id: root
    implicitWidth: opts.implicitWidth
    implicitHeight: opts.implicitHeight

    component PowerOption: ActionButton {
        id: option
        required property list<string> command
        required property color optionColor

        readonly property int textPixelSize: 24
        readonly property int iconSize: Math.round((label ? label.implicitHeight : textPixelSize) * 1.5)
        readonly property int gutter: 4
        readonly property int indicatorLane: 4
        readonly property int horizontalOuterMargin: 8
        readonly property int verticalOuterMargin: 4
        readonly property bool hasExplicitIconSource: !!option.iconSource && option.iconSource.toString() !== ""
        readonly property var resolvedIconSource: hasExplicitIconSource ? option.iconSource : Quickshell.iconPath(option.iconName || "dialog-warning", "dialog-warning")

        implicitWidth: horizontalOuterMargin + iconSize + gutter + (label ? label.implicitWidth : 0) + horizontalOuterMargin
        implicitHeight: Math.max(iconSize, label ? label.implicitHeight : 0) + 2 * verticalOuterMargin
        accentColor: optionColor
        highlightSide: ActiveIndicator.Side.Left
        highlightAnimationMode: ActiveIndicator.AnimationMode.GrowAlong
        highlightThickness: indicatorLane
        indicatorOnHover: true
        scaleTarget: null
        scaleText: true
        textScaleTarget: label
        hoveredScale: 1.0
        unhoveredScale: 0.8
        flat: true

        Process {
            id: runner
        }

        onClicked: runner.exec({
                "command": option.command
            })
        contentItem: Item {
            implicitWidth: row.implicitWidth + 2 * horizontalOuterMargin
            implicitHeight: row.implicitHeight + 2 * verticalOuterMargin

            RowLayout {
                id: row
                anchors.left: parent.left
                anchors.leftMargin: horizontalOuterMargin
                anchors.right: parent.right
                anchors.rightMargin: horizontalOuterMargin
                anchors.top: parent.top
                anchors.topMargin: verticalOuterMargin
                anchors.bottom: parent.bottom
                anchors.bottomMargin: verticalOuterMargin
                spacing: gutter

                Item {
                    Layout.preferredWidth: iconSize
                    Layout.minimumWidth: iconSize
                    Layout.maximumWidth: iconSize
                    Layout.preferredHeight: iconSize
                    Layout.alignment: Qt.AlignVCenter

                    Icon {
                        anchors.fill: parent
                        implicitSize: iconSize
                        source: option.resolvedIconSource
                        color: option.optionColor
                        smooth: true
                    }
                }

                Text {
                    id: label
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    text: option.text
                    color: Config.styling.text0
                    font.bold: true
                    font.pixelSize: textPixelSize
                    transformOrigin: Item.Left

                    Behavior on scale {
                        enabled: Config.behaviour.animation.enabled
                        NumberAnimation {
                            duration: Config.behaviour.animation.calc(0.1)
                            easing.type: Easing.Bezier
                            easing.bezierCurve: [0.4, 0.0, 0.2, 1.0]
                        }
                    }
                }
            }
        }
    }

    ColumnLayout {
        id: opts
        spacing: 8

        PowerOption {
            Layout.fillWidth: true
            command: ["uwsm", "stop"]
            optionColor: Config.colors.yellow
            iconSource: Quickshell.iconPath("system-log-out-symbolic", "dialog-warning")
            text: "Logout"
        }

        PowerOption {
            Layout.fillWidth: true
            command: ["systemctl", "hibernate"]
            optionColor: Config.colors.sapphire
            iconSource: Quickshell.iconPath("system-suspend-hibernate-symbolic", "dialog-warning")
            text: "Hibernate"
        }

        PowerOption {
            Layout.fillWidth: true
            command: ["systemctl", "reboot"]
            optionColor: Config.colors.peach
            iconSource: Quickshell.iconPath("system-reboot-symbolic", "dialog-warning")
            text: "Reboot"
        }

        PowerOption {
            Layout.fillWidth: true
            command: ["systemctl", "poweroff"]
            optionColor: Config.colors.red
            iconSource: Quickshell.iconPath("system-shutdown-symbolic", "dialog-warning")
            text: "Shutdown"
        }
    }
}
