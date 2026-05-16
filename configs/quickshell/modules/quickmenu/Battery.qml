import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower

import qs.services
import qs.components

ColumnLayout {
    id: root

    property UPowerDevice bat: UPower.displayDevice
    property bool powerModesFirst: false

    readonly property int contentWidth: width > 0 ? width : 320
    readonly property int sectionSpacing: Config.spacing.xs
    readonly property int buttonSpacing: 3
    readonly property int rowHeight: 36
    readonly property int iconSize: 20
    readonly property int iconSlotWidth: 24
    readonly property int iconTextGap: 10
    readonly property int horizontalPadding: 8
    readonly property int verticalPadding: 4
    readonly property int buttonIconSize: 28
    readonly property int buttonTextPixelSize: 18
    readonly property int buttonIconSlotWidth: 28

    readonly property color stateColor: {
        let percentage = Math.floor((bat?.percentage || 0) * 100);
        return [
            {
                max: 10,
                col: Config.styling.critical
            },
            {
                max: 20,
                col: Config.colors.yellow
            },
            {
                max: 60,
                col: Config.styling.text0
            },
            {
                max: 100,
                col: Config.styling.good
            }
        ].find(({ max }) => percentage <= max).col;
    }

    function formatDuration(seconds, prefix) {
        if (!seconds || seconds <= 0)
            return "";

        let h = Math.floor(seconds / 3600);
        let m = Math.floor(seconds / 60) % 60;
        return `${prefix}${h}h${m}m`;
    }

    readonly property string batteryDetail: {
        if (!bat)
            return "";

        if (bat.state === UPowerDeviceState.Charging)
            return formatDuration(bat.timeToFull, "Full in ");

        return formatDuration(bat.timeToEmpty, "Empty in ");
    }

    readonly property string summaryText: {
        if (!bat)
            return "No battery detected";

        const percentage = `${Math.floor((bat.percentage || 0) * 100)}%`;
        return batteryDetail !== "" ? `${percentage} • ${batteryDetail}` : percentage;
    }

    component ProfileButton: ActionButton {
        id: option

        required property int mode
        required property color optionColor

        readonly property bool isActive: PowerProfiles.profile === mode

        implicitWidth: root.contentWidth
        implicitHeight: root.rowHeight
        active: isActive
        accentColor: optionColor
        fillOpacity: isActive ? 0.28 : Config.behaviour.hoverBgOpacity
        highlightSide: ActiveIndicator.Side.Left
        highlightAnimationMode: ActiveIndicator.AnimationMode.GrowAlong
        highlightThickness: Config.spacing.xxs
        scaleText: true
        textScaleTarget: profileLabel
        hoveredScale: 1.0
        unhoveredScale: 0.8

        onClicked: PowerProfiles.profile = mode

        contentItem: Item {
            implicitWidth: row.implicitWidth + 2 * root.horizontalPadding
            implicitHeight: row.implicitHeight + 2 * root.verticalPadding

            RowLayout {
                id: row
                anchors {
                    left: parent.left
                    leftMargin: root.horizontalPadding
                    right: parent.right
                    rightMargin: root.horizontalPadding
                    top: parent.top
                    topMargin: root.verticalPadding
                    bottom: parent.bottom
                    bottomMargin: root.verticalPadding
                }
                spacing: root.iconTextGap

                Item {
                    Layout.preferredWidth: root.buttonIconSlotWidth
                    Layout.minimumWidth: root.buttonIconSlotWidth
                    Layout.maximumWidth: root.buttonIconSlotWidth
                    Layout.preferredHeight: root.buttonIconSize
                    Layout.alignment: Qt.AlignVCenter

                    Icon {
                        id: profileIcon
                        anchors.fill: parent
                        iconName: option.iconName
                        color: option.optionColor
                        implicitSize: root.buttonIconSize
                        smooth: true
                        scale: option.hovered ? 1.15 : 1.0

                        Behavior on scale {
                            NumberAnimation {
                                duration: option.scaleAnimationDuration
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                }

                Text {
                    id: profileLabel
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    text: option.text
                    color: option.isActive ? option.optionColor : Config.styling.text0
                    font.bold: true
                    font.pixelSize: root.buttonTextPixelSize
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

    implicitWidth: 320
    width: parent ? parent.width : implicitWidth
    spacing: root.sectionSpacing

    component SummaryBlock: ColumnLayout {
        Layout.fillWidth: true
        spacing: Config.spacing.xxs

        RowLayout {
            Layout.fillWidth: true
            spacing: root.iconTextGap

            Item {
                Layout.preferredWidth: root.iconSlotWidth
                Layout.minimumWidth: root.iconSlotWidth
                Layout.maximumWidth: root.iconSlotWidth
                Layout.preferredHeight: root.iconSlotWidth

                Icon {
                    anchors.centerIn: parent
                    iconName: bat?.iconName || "battery-missing-symbolic"
                    color: root.stateColor
                    implicitSize: root.iconSize
                }
            }

            Text {
                text: bat ? "Charge level" : "Battery unavailable"
                color: Config.styling.text0
                font.pixelSize: 16
                font.bold: true
            }

            Item {
                Layout.fillWidth: true
            }

            Text {
                visible: !!bat
                text: `${Math.floor((bat?.percentage || 0) * 100)}%`
                color: root.stateColor
                font.pixelSize: 18
                font.bold: true
            }
        }

        Text {
            Layout.fillWidth: true
            visible: text !== ""
            text: root.batteryDetail
            color: Config.styling.text2
            font.pixelSize: 12
        }
    }

    component PowerModesBlock: ColumnLayout {
        Layout.fillWidth: true
        spacing: root.buttonSpacing

        Text {
            Layout.fillWidth: true
            text: "Power mode"
            color: Config.styling.text1
            font.pixelSize: 14
            font.bold: true
        }

        ProfileButton {
            Layout.fillWidth: true
            mode: PowerProfile.PowerSaver
            text: "Power Saver"
            iconName: "power-profile-power-saver-symbolic"
            optionColor: Config.styling.good
        }

        ProfileButton {
            Layout.fillWidth: true
            mode: PowerProfile.Balanced
            text: "Balanced"
            iconName: "power-profile-balanced-symbolic"
            optionColor: Config.colors.yellow
        }

        ProfileButton {
            Layout.fillWidth: true
            mode: PowerProfile.Performance
            text: "Performance"
            iconName: "power-profile-performance-symbolic"
            optionColor: Config.styling.critical
        }
    }

    PowerModesBlock {
        Layout.fillWidth: true
        visible: root.powerModesFirst
    }

    Rectangle {
        Layout.fillWidth: true
        visible: root.powerModesFirst
        implicitHeight: 1
        color: Config.styling.bg3
    }

    SummaryBlock {
        Layout.fillWidth: true
    }

    Rectangle {
        Layout.fillWidth: true
        visible: !root.powerModesFirst
        implicitHeight: 1
        color: Config.styling.bg3
    }

    PowerModesBlock {
        Layout.fillWidth: true
        visible: !root.powerModesFirst
    }
}
