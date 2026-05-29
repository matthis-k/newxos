import QtQml
import Quickshell
import "../logic/CommandTree.js" as CommandTree

CommandTreeBackendBase {
    id: root

    category: qsTr("Web Search")

    backendId: "web"
    name: qsTr("Web Search")
    helpTitle: qsTr("Web Search")
    helpDescription: qsTr("Search the web or a named engine")
    helpIcon: "internet-web-browser"
    helpPrefixes: ["@web", "@g", "@ddg", "@gh", "@yt"]
    priority: 20
    maxResults: 1
    routes: [
        { pattern: "^@web\\s+(.*)", mode: "exclusive" },
        { pattern: "^@g\\s+(.*)", mode: "exclusive" },
        { pattern: "^@ddg\\s+(.*)", mode: "exclusive" },
        { pattern: "^@gh\\s+(.*)", mode: "exclusive" },
        { pattern: "^@yt\\s+(.*)", mode: "exclusive" },
        { pattern: "^.*$", mode: "fallback" }
    ]

    treePrefixes: ["@web", "@g", "@ddg", "@gh", "@yt"]
    treeRoots: engineTree

    readonly property var engines: ({
        "g": { prefix: "@g", name: "Google", url: "https://google.com/search?q=%1" },
        "ddg": { prefix: "@ddg", name: "DuckDuckGo", url: "https://duckduckgo.com/?q=%1" },
        "gh": { prefix: "@gh", name: "GitHub", url: "https://github.com/search?q=%1" },
        "yt": { prefix: "@yt", name: "YouTube", url: "https://www.youtube.com/results?search_query=%1" }
    })

    readonly property var engineTree: Object.keys(engines).map(id => ({
        id: id,
        title: engines[id].name,
        subtitle: engines[id].prefix,
        icon: "internet-web-browser",
        action: { engineId: id }
    }))

    function activate(result, action) {
        const metadata = result ? result.metadata || {} : {};
        const cmdAction = metadata.action || {};
        const engineId = metadata.engineId || cmdAction.engineId;
        const engine = engineId ? root.engines[engineId] : null;
        if (!engine)
            return;

        const searchQuery = metadata.query || "";
        const encoded = encodeURIComponent(searchQuery);
        Quickshell.execDetached({ command: ["xdg-open", engine.url.replace("%1", encoded)] });
    }
}
