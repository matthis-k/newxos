import QtQuick
import qs.services
import qs.components

ActionButton {
    id: root
    property var screenState
    property string tabName: ""
    property string iconName: "dialog-warning"
    property string fallbackIconName: "dialog-warning"
    property var iconColor: Config.styling.text0
    property string badgeText: ""
    property color badgeColor: Config.styling.primaryAccent
    property alias smooth: statusIcon.smooth
    property alias mipmap: statusIcon.mipmap

    readonly property bool expanded: !!screenState && screenState.barExpandedForDashboard
    readonly property int transitionMs: screenState
        ? screenState.dashboardTransitionMs
        : (Config.behaviour.animation.enabled ? Config.behaviour.animation.calc(0.18) : 0)

    implicitWidth: parent ? parent.height : 24
    implicitHeight: parent ? parent.height : 24

    backgroundColor: Config.styling.bg3
    active: screenState ? screenState.isIndicatorActive(tabName) : false
    scaleTarget: null
    scaleIcon: true
    iconScaleTarget: statusIcon
    hoveredScale: 1.0
    unhoveredScale: expanded || active ? 1.0 : 0.8

    contentItem: Icon {
        id: statusIcon
        iconName: root.iconName
        fallbackIconName: root.fallbackIconName
        color: root.iconColor
        implicitSize: (parent ? parent.height : root.implicitHeight) * 0.7

        Badge {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: -2
            anchors.rightMargin: -2
            text: root.badgeText
            badgeColor: root.badgeColor
        }
    }

    Behavior on x {
        NumberAnimation {
            duration: root.transitionMs
            easing.type: Easing.OutCubic
        }
    }

    Behavior on width {
        NumberAnimation {
            duration: root.transitionMs
            easing.type: Easing.OutCubic
        }
    }

    onClicked: {
        if (!screenState || tabName === "")
            return;

        screenState.toggleDashboard(tabName);
    }
}
