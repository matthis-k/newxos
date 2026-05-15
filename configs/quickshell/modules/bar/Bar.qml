import QtQuick
import QtQuick.Layouts
import qs.utils
import qs.utils.types
import qs.services
import qs.components
import qs.modules.quickmenu

Rectangle {
    id: barRoot
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
            left: barRoot.left
            right: barRoot.right
            bottom: barRoot.bottom
        }
        implicitHeight: 1
    }

    RowLayout {
        id: left
        anchors {
            top: barRoot.top
            bottom: sepline.top
            left: barRoot.left
        }
        HyprlandWidget {}
    }

    RowLayout {
        id: center
        anchors {
            top: barRoot.top
            bottom: sepline.top
            horizontalCenter: barRoot.horizontalCenter
        }
        Clock {
            format: "HH:mm"
        }
    }

    RowLayout {
        id: right
        anchors {
            top: barRoot.top
            bottom: sepline.top
            right: barRoot.right
        }
        width: barRoot.rightExpanded ? barRoot.screenState.dashboardWidth : implicitWidth
        spacing: barRoot.rightExpanded ? Config.spacing.xxs : 0

        Behavior on width {
            NumberAnimation {
                duration: barRoot.screenState ? barRoot.screenState.dashboardTransitionMs : 0
                easing.type: Easing.OutCubic
            }
        }

        Behavior on spacing {
            NumberAnimation {
                duration: barRoot.screenState ? barRoot.screenState.dashboardTransitionMs : 0
                easing.type: Easing.OutCubic
            }
        }

        OverviewIcon {
            screenState: barRoot.screenState
            Layout.fillWidth: barRoot.fillFlag()
        }
        AudioIcon {
            screenState: barRoot.screenState
            Layout.fillWidth: barRoot.fillFlag()
        }
        NotificationIcon {
            screenState: barRoot.screenState
            Layout.fillWidth: barRoot.fillFlag()
        }
        BluetoothIcon {
            screenState: barRoot.screenState
            Layout.fillWidth: barRoot.fillFlag()
        }
        NetworkIcon {
            screenState: barRoot.screenState
            Layout.fillWidth: barRoot.fillFlag()
        }
        EnergyIcon {
            screenState: barRoot.screenState
            Layout.fillWidth: barRoot.fillFlag()
        }
        StatsIcon {
            screenState: barRoot.screenState
            Layout.fillWidth: barRoot.fillFlag()
        }
    }
}
