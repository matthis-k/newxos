import QtQuick

import qs.services
import qs.components

Item {
    id: root

    required property var node
    property bool isInput: false
    property int sliderHeight: 24
    property int sliderWidth: 100
    property int iconSlotWidth: 28
    property int iconTextGap: 10
    property int iconSize: 20

    readonly property int volume: AudioService.volumePercent(root.node)

    implicitWidth: root.sliderWidth + root.iconSlotWidth + root.iconTextGap + 42
    implicitHeight: root.sliderHeight

    AudioLevelSlider {
        anchors.fill: parent
        iconName: AudioService.volumeIconName(root.node, root.isInput)
        iconColor: AudioService.isMuted(root.node) ? Config.styling.critical : Config.styling.text0
        valueText: `${root.volume}%`
        from: 0
        to: 150
        value: root.volume
        stepSize: 1
        enabled: !!root.node
        accentColor: AudioService.isMuted(root.node) ? Config.styling.critical : Config.colors.blue
        iconSize: root.iconSize
        onIconClicked: AudioService.toggleMute(root.node)
        onValueModified: value => AudioService.setVolume(root.node, value)
    }
}
