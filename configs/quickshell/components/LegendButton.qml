import QtQuick
import QtQuick.Layouts
import qs.services

Item {
    id: root

    required property var graphView
    property string seriesName: ""
    property var seriesFilter: null
    required property color color

    default property alias content: contentRow.children

    property bool checked: true

    implicitHeight: 20

    function refreshChecked() {
        if (!graphView || !graphView.getSeries || !graphView.isSeriesVisible)
            return;

        const names = graphView.getSeries(seriesFilter || seriesName);
        if (names.length === 0)
            return;

        root.checked = names.some(n => graphView.isSeriesVisible(n) === true);
    }

    function _refreshLater() {
        Qt.callLater(root.refreshChecked);
    }

    Component.onCompleted: root._refreshLater()

    onGraphViewChanged: root._refreshLater()
    onSeriesNameChanged: root._refreshLater()
    onSeriesFilterChanged: root._refreshLater()

    Connections {
        target: root.graphView || null

        function onVisibilityChanged() {
            root.refreshChecked();
        }
    }

    Rectangle {
        anchors.fill: parent
        anchors.topMargin: 2
        anchors.bottomMargin: 2
        radius: 3
        color: root.color
        opacity: root.checked ? 1.0 : 0.5
        Behavior on opacity {
            NumberAnimation {
                duration: Config.behaviour.animation.enabled ? Config.behaviour.animation.calc(0.12) : 0
                easing.type: Easing.OutCubic
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            const names = graphView.getSeries(seriesFilter || seriesName);
            if (names.length === 0)
                return;
            const currentlyVisible = names.some(n => graphView.isSeriesVisible(n) === true);
            const target = !currentlyVisible;
            if (graphView.batch) {
                graphView.batch(() => {
                    names.forEach(n => graphView.setSeriesVisible(n, target));
                });
            } else {
                names.forEach(n => graphView.setSeriesVisible(n, target));
            }
        }
    }

    RowLayout {
        id: contentRow
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 4
    }
}
