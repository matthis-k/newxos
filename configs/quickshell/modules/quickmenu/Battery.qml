import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import Quickshell.Services.UPower

import qs.animations as Animations
import qs.services
import qs.services as Services
import qs.components
import qs.utils

ColumnLayout {
    id: root

    property UPowerDevice bat: Services.Stats.battery
    property bool powerModesFirst: false
    property bool showGraph: true
    property bool graphActive: true
    readonly property bool hasBattery: Services.Stats.hasBattery

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
        const percentage = Math.floor((bat?.percentage || 0) * 100);
        percentage <= 10 ? Config.styling.critical :
        percentage <= 20 ? Config.colors.yellow :
        percentage <= 60 ? Config.styling.text0 :
        Config.styling.good;
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

    function batteryGraphSeries() {
        const _ = Services.Stats.graphRevision;
        return Services.Stats.calculateBatteryGraphSeries().map(series => Object.assign({}, series, {
                color: root.stateColor
            }));
    }

    function modeIndex(mode) {
        switch (mode) {
        case PowerProfile.PowerSaver:
            return 0;
        case PowerProfile.Performance:
            return 2;
        default:
            return 1;
        }
    }

    function modeFromIndex(index) {
        switch (Math.round(index)) {
        case 0:
            return PowerProfile.PowerSaver;
        case 2:
            return PowerProfile.Performance;
        default:
            return PowerProfile.Balanced;
        }
    }

    function modeLabel(mode) {
        switch (mode) {
        case PowerProfile.PowerSaver:
            return "Power Saver";
        case PowerProfile.Performance:
            return "Performance";
        default:
            return "Balanced";
        }
    }

    function modeColor(mode) {
        switch (mode) {
        case PowerProfile.PowerSaver:
            return Config.styling.good;
        case PowerProfile.Performance:
            return Config.styling.critical;
        default:
            return Config.colors.yellow;
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
        spacing: Config.spacing.xs

        Item {
            id: modeLabelSlot

            Layout.fillWidth: true
            Layout.preferredHeight: modeLabel.implicitHeight
            clip: true

            property int displayedIndex: root.modeIndex(PowerProfiles.profile)
            property string displayedText: root.modeLabel(PowerProfiles.profile)
            property color displayedColor: root.modeColor(PowerProfiles.profile)

            function labelX() {
                if (displayedIndex === 0)
                    return 0;
                if (displayedIndex === 2)
                    return Math.max(0, width - modeLabel.implicitWidth);
                return Math.round((width - modeLabel.implicitWidth) / 2);
            }

            function syncLabel() {
                displayedIndex = root.modeIndex(PowerProfiles.profile);
                displayedText = root.modeLabel(PowerProfiles.profile);
                displayedColor = root.modeColor(PowerProfiles.profile);
            }

            Connections {
                target: PowerProfiles

                function onProfileChanged() {
                    if (labelMorph.running)
                        labelMorph.restart();
                    else
                        labelMorph.start();
                }
            }

            Text {
                id: modeLabel

                x: modeLabelSlot.labelX()
                text: modeLabelSlot.displayedText
                color: modeLabelSlot.displayedColor
                font.pixelSize: root.buttonTextPixelSize
                font.bold: true

                Animations.ShiftBehavior on x {
                }

                Animations.StateColorBehavior on color {
                }
            }

            SequentialAnimation {
                id: labelMorph

                Animations.FadeOutAnimation {
                    target: modeLabel
                    property: "opacity"
                    to: 0
                }

                ScriptAction {
                    script: modeLabelSlot.syncLabel()
                }

                Animations.FadeInAnimation {
                    target: modeLabel
                    property: "opacity"
                    to: 1
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Config.spacing.sm

            Icon {
                iconName: "power-profile-power-saver-symbolic"
                color: Config.styling.good
                implicitSize: root.buttonIconSize
                Layout.preferredWidth: root.buttonIconSlotWidth
                Layout.preferredHeight: root.buttonIconSize
                Layout.alignment: Qt.AlignVCenter
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: modeSlider.implicitHeight
                Layout.alignment: Qt.AlignVCenter

                StyledSlider {
                    id: modeSlider
                    anchors.fill: parent
                    from: 0
                    to: 2
                    stepSize: 1
                    snapMode: Slider.SnapAlways
                    accentColor: root.modeColor(PowerProfiles.profile)

                    Binding {
                        target: modeSlider
                        property: "value"
                        value: root.modeIndex(PowerProfiles.profile)
                        when: !modeSlider.pressed
                    }

                    onMoved: PowerProfiles.profile = root.modeFromIndex(value)
                    onPressedChanged: {
                        if (!pressed)
                            PowerProfiles.profile = root.modeFromIndex(value);
                    }
                }

                Rectangle {
                    width: 2
                    height: 8
                    radius: width / 2
                    color: Config.styling.bg8
                    x: Math.round(parent.width / 2 - width / 2)
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Icon {
                iconName: "power-profile-performance-symbolic"
                color: Config.styling.critical
                implicitSize: root.buttonIconSize
                Layout.preferredWidth: root.buttonIconSlotWidth
                Layout.preferredHeight: root.buttonIconSize
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }

    PowerModesBlock {
        Layout.fillWidth: true
        visible: root.powerModesFirst && root.hasBattery
    }

    Rectangle {
        Layout.fillWidth: true
        visible: root.powerModesFirst && root.hasBattery
        implicitHeight: 1
        color: Config.styling.bg3
    }

    SummaryBlock {
        Layout.fillWidth: true
        visible: root.hasBattery
    }

    Rectangle {
        Layout.fillWidth: true
        visible: !root.powerModesFirst
        implicitHeight: 1
        color: Config.styling.bg3
    }

    PowerModesBlock {
        Layout.fillWidth: true
        visible: !root.powerModesFirst && root.hasBattery
    }

    Rectangle {
        id: graphSeparator

        Layout.fillWidth: true
        visible: root.showGraph && root.hasBattery
        implicitHeight: 1
        color: Config.styling.bg3
    }

    ColumnLayout {
        id: graphSection

        Layout.fillWidth: true
        visible: root.showGraph && root.hasBattery
        spacing: Config.spacing.xs
        Text {
            Layout.fillWidth: true
            text: qsTr("Battery history (5h)")
            color: Config.styling.text1
            font.pixelSize: 14
            font.bold: true
        }

        GraphView {
            id: batteryGraph
            active: root.graphActive && root.showGraph
            yMin: 0
            yMax: 100
            xWindow: 18000000
            xMarkerInterval: 3600000
            xMarkerLabel: (x, view) => x < view.maxX ? qsTr("%1h").arg(Math.round((view.maxX - x) / 3600000)) : ""
            graphs: root.batteryGraphSeries()
            Layout.fillWidth: true
            Layout.preferredHeight: 160
            Layout.minimumHeight: 120
        }
    }
}
