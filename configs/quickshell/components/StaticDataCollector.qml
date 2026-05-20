import QtQuick

DataCollector {
    id: root

    property var source: []

    onSourceChanged: root.replaceRawData(source || [])
    Component.onCompleted: root.replaceRawData(source || [])
}
