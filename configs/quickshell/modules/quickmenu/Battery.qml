import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.UPower

import qs.services
import qs.components

Item {
    id: root
    width: implicitWidth
    height: implicitHeight
    implicitWidth: columnLayout.implicitWidth
    implicitHeight: columnLayout.implicitHeight
    property UPowerDevice bat: UPower.displayDevice

    property color stateColor: {
        let percentage = Math.floor(bat.percentage * 100);
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
        ].find(({
                max,
                col
            }) => percentage <= max).col;
    }

    ColumnLayout {
        id: columnLayout
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: `Battery status:`
                color: Config.styling.text0
                font.pixelSize: 24
            }
            Text {
                text: `${Math.floor(bat.percentage * 100)}%`
                color: stateColor
                font.pixelSize: 24
                font.bold: true
            }
        }

        Text {
            visible: bat.state == UPowerDeviceState.Charging
            color: Config.styling.text0
            text: {
                let time = bat.timeToFull;
                let h = Math.floor(time / 60 / 60);
                let m = Math.floor(time / 60) % 60;
                return `Full in: ${h}h${m}m`;
            }
        }

        Text {
            visible: bat.state != UPowerDeviceState.Charging
            color: Config.styling.text0
            text: {
                let time = bat.timeToEmpty;
                let h = Math.floor(time / 60 / 60);
                let m = Math.floor(time / 60) % 60;
                return `Empty in ${h}h${m}m`;
            }
        }

        Item {
            id: powerProfileArea
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            implicitWidth: powerProfileRow.implicitWidth + 8
            implicitHeight: Math.max(40, powerProfileRow.implicitHeight + 8)

            property int accumulatedScroll: 0
            property int scrollThreshold: 120

            function rotateProfile(direction) {
                const order = [PowerProfile.PowerSaver, PowerProfile.Balanced, PowerProfile.Performance];
                let current = PowerProfiles.profile;
                let index = order.indexOf(current);
                let nextIndex = (index + direction + order.length) % order.length;
                PowerProfiles.profile = order[nextIndex];
            }

            TapHandler {
                acceptedButtons: Qt.LeftButton
                cursorShape: Qt.PointingHandCursor
                gesturePolicy: TapHandler.ReleaseWithinBounds
                onTapped: powerProfileArea.rotateProfile(+1)
            }

            WheelHandler {
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onWheel: {
                    powerProfileArea.accumulatedScroll += wheel.angleDelta.y;
                    if (powerProfileArea.accumulatedScroll >= powerProfileArea.scrollThreshold) {
                        powerProfileArea.rotateProfile(+1);
                        powerProfileArea.accumulatedScroll = 0;
                    } else if (powerProfileArea.accumulatedScroll <= -powerProfileArea.scrollThreshold) {
                        powerProfileArea.rotateProfile(-1);
                        powerProfileArea.accumulatedScroll = 0;
                    }
                }
            }

            RowLayout {
                id: powerProfileRow
                spacing: 8
                anchors.fill: parent
                anchors.margins: 4

                ColorOverlay {
                    id: powerProfileIcon2
                    property string iconName: ({
                            [PowerProfile.Performance]: "power-profile-performance-symbolic",
                            [PowerProfile.Balanced]: "power-profile-balanced-symbolic",
                            [PowerProfile.PowerSaver]: "power-profile-power-saver-symbolic"
                        })[PowerProfiles.profile]
                    color: ({
                            [PowerProfile.Performance]: Config.styling.critical,
                            [PowerProfile.Balanced]: Config.colors.yellow,
                            [PowerProfile.PowerSaver]: Config.styling.good
                        })[PowerProfiles.profile]
                    implicitWidth: 32
                    implicitHeight: 32
                    source: Icon {
                        source: Quickshell.iconPath(powerProfileIcon2.iconName)
                        implicitSize: 32
                    }
                }

                ColumnLayout {
                    spacing: 0
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        text: "Power profile"
                        font.pixelSize: 16
                        color: Config.styling.text0
                        font.bold: true
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: PowerProfile.toString(PowerProfiles.profile)
                        color: Config.styling.text2
                        font.pixelSize: 12
                    }
                }
            }
        }
    }
}
