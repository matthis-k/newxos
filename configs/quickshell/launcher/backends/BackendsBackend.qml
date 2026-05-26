import QtQml
import Quickshell
import "../logic/QueryParsing.js" as QueryParsing

LauncherBackendBase {
    id: root

    property string category: qsTr("Launcher Backends")
    property var describedBackends: []

    backendId: "backends"
    name: qsTr("Launcher Backends")
    helpTitle: qsTr("Launcher Backends")
    helpDescription: qsTr("Show available launcher sources")
    helpIcon: "help-about"
    helpPrefixes: ["?"]
    priority: 110
    maxResults: 16

    function canHandle(query) {
        const parsed = QueryParsing.parse(query);
        return enabled && parsed.targetBackend === root.backendId;
    }

    function search(query, context) {
        const parsed = QueryParsing.parse(query);
        const filter = parsed.text.toLowerCase();
        const results = [];

        for (const backend of describedBackends) {
            if (!backend || !backend.enabled || !backend.helpPrefixes || backend.helpPrefixes.length === 0)
                continue;

            const prefixes = backend.helpPrefixes.join(", ");
            const searchable = [backend.helpTitle, backend.helpDescription, prefixes].join(" ").toLowerCase();
            if (filter && searchable.indexOf(filter) < 0)
                continue;

            results.push({
                id: "backend:" + backend.backendId,
                source: root.backendId,
                category: root.category,
                title: backend.helpTitle,
                subtitle: prefixes + " - " + backend.helpDescription,
                icon: backend.helpIcon || "system-search",
                relevance: 1,
                actions: [
                    { id: "use-prefix", label: qsTr("Use prefix"), icon: "go-next", default: true }
                ],
                metadata: {
                    prefix: backend.helpPrefixes[0],
                    replaceQuery: backend.helpPrefixes[0] + " "
                }
            });
        }

        return results.slice(0, root.maxResults);
    }

    function activate(result, action) {}
}
