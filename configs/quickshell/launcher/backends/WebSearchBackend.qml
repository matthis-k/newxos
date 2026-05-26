import QtQml
import Quickshell
import "../logic/QueryParsing.js" as QueryParsing

LauncherBackendBase {
    id: root

    property string category: qsTr("Web Search")
    property string defaultEngine: "ddg"
    property var engines: ({
        "g": { prefix: "g", name: "Google", url: "https://google.com/search?q=%1" },
        "ddg": { prefix: "ddg", name: "DuckDuckGo", url: "https://duckduckgo.com/?q=%1" },
        "gh": { prefix: "gh", name: "GitHub", url: "https://github.com/search?q=%1" },
        "yt": { prefix: "yt", name: "YouTube", url: "https://www.youtube.com/results?search_query=%1" }
    })

    backendId: "web"
    name: qsTr("Web Search")
    helpTitle: qsTr("Web Search")
    helpDescription: qsTr("Search the web or a named engine")
    helpIcon: "internet-web-browser"
    helpPrefixes: ["@web", "g", "ddg", "gh", "yt"]
    priority: 20
    maxResults: 1

    function canHandle(query) {
        const parsed = QueryParsing.parse(query);
        const text = parsed.targetBackend === root.backendId ? parsed.text : parsed.raw;
        return enabled
            && text.length > 0
            && text[0] !== "~"
            && text[0] !== "/"
            && parsed.targetBackend !== "calculator"
            && parsed.targetBackend !== "desktop"
            && parsed.targetBackend !== "files"
            && parsed.targetBackend !== "backends";
    }

    function engineFor(parsed) {
        const explicitEngine = parsed && parsed.engine && parsed.engine !== "default" ? parsed.engine : root.defaultEngine;
        return root.engines[explicitEngine] || root.engines[root.defaultEngine] || root.engines.ddg;
    }

    function search(query, context) {
        const parsed = QueryParsing.parse(query);
        const searchQuery = parsed.targetBackend === root.backendId ? parsed.text : parsed.raw;
        if (!searchQuery)
            return [];

        const engine = engineFor(parsed);
        const encoded = encodeURIComponent(searchQuery);
        const explicitWeb = QueryParsing.isExplicitFor(parsed, root.backendId);

        return [{
            id: "web:" + engine.prefix + ":" + searchQuery,
            source: root.backendId,
            category: root.category,
            title: qsTr("Search %1 for \"%2\"").arg(engine.name).arg(searchQuery),
            subtitle: engine.name,
            icon: "internet-web-browser",
            relevance: explicitWeb ? 1 : 0.3,
            actions: [
                { id: "search", label: qsTr("Search"), icon: "system-search", default: true }
            ],
            metadata: {
                engine: engine.prefix,
                query: searchQuery,
                url: engine.url.replace("%1", encoded)
            }
        }];
    }

    function activate(result, action) {
        if (!result || !result.metadata || !result.metadata.url)
            return;

        Quickshell.execDetached({ command: ["xdg-open", result.metadata.url] });
    }
}
