import QtQml

QtObject {
    property string backendId: ""
    property string name: ""
    property string helpTitle: name
    property string helpDescription: ""
    property string helpIcon: "system-search"
    property var helpPrefixes: []
    property bool enabled: true
    property int priority: 0
    property int maxResults: 5

    function canHandle(query) {
        return enabled && query.length > 0;
    }

    function search(query, context) {
        return [];
    }

    function activate(result, action) {
    }
}
