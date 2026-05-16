import QtQuick
import QtQuick.Layouts
import qs.utils
import qs.utils.types
import qs.services
import qs.components
import qs.modules.quickmenu

Rectangle {
    id: root
    property var screenState
    anchors.fill: parent
    color: Config.styling.bg0

    readonly property bool rightExpanded: !!screenState && screenState.barExpandedForDashboard

    function fillFlag() {
        return rightExpanded;
    }

    Rectangle {
        id: sepline
        color: Config.styling.primaryAccent
        anchors {
            left: root.left
            right: root.right
            bottom: root.bottom
        }
        implicitHeight: 1
    }

    RowLayout {
        id: left
        anchors {
            top: root.top
            bottom: sepline.top
            left: root.left
        }
        HyprlandWidget {}
    }

    RowLayout {
        id: center
        anchors {
            top: root.top
            bottom: sepline.top
            horizontalCenter: root.horizontalCenter
        }
        Clock {
            format: "HH:mm"
        }
    }

    RowLayout {
        id: right
        anchors {
            top: root.top
            bottom: sepline.top
            right: root.right
        }
        width: root.rightExpanded ? root.screenState.dashboardWidth : implicitWidth
        spacing: root.rightExpanded ? Config.spacing.xxs : 0

        Behavior on width {
            NumberAnimation {
                duration: root.screenState ? root.screenState.dashboardTransitionMs : 0
                easing.type: Easing.OutCubic
            }
        }

        Behavior on spacing {
            NumberAnimation {
                duration: root.screenState ? root.screenState.dashboardTransitionMs : 0
                easing.type: Easing.OutCubic
            }
        }

        OverviewIcon {
            screenState: root.screenState
            Layout.fillWidth: root.fillFlag()
        }
        AudioIcon {
            screenState: root.screenState
            Layout.fillWidth: root.fillFlag()
        }
        NotificationIcon {
            screenState: root.screenState
            Layout.fillWidth: root.fillFlag()
        }
        BluetoothIcon {
            screenState: root.screenState
            Layout.fillWidth: root.fillFlag()
        }
        NetworkIcon {
            screenState: root.screenState
            Layout.fillWidth: root.fillFlag()
        }
        EnergyIcon {
            screenState: root.screenState
            Layout.fillWidth: root.fillFlag()
        }
        StatsIcon {
            screenState: root.screenState
            Layout.fillWidth: root.fillFlag()
        }
    }
}
