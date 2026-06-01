import QtQml
import Quickshell
import "../logic/CommandTree.js" as CommandTree
import "../logic/CompositeSearch.js" as CompositeSearch

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

    function rootNode(query, context) {
        const searchText = query ? query.raw.trim() : "";
        const directivePrefix = context && context.directive ? context.directive.prefix : "";
        if (!directivePrefix && (searchText[0] === "/" || searchText[0] === "~" || searchText.indexOf("file://") === 0 || /^@?files?(\s|$)/.test(searchText)))
            return null;

        const children = [];
        for (const id of Object.keys(root.engines)) {
            const engine = root.engines[id];
            if (directivePrefix && directivePrefix !== "@web" && directivePrefix !== engine.prefix)
                continue;
            children.push(CompositeSearch.makeNode({
                id: "web:" + id + ":" + searchText,
                backendId: root.backendId,
                kind: "desktop-action",
                label: searchText ? qsTr("Search %1").arg(engine.name) : engine.name,
                subtitle: searchText ? searchText : engine.prefix,
                icon: root.helpIcon,
                aliases: [engine.name, engine.prefix, id],
                keywords: ["web", "search", engine.name, id, searchText],
                actionList: [CompositeSearch.makeAction("search", qsTr("Search"), { engineId: id, query: searchText })],
                semanticTerms: [{ triggers: ["search", "web", id], matches: ["search", "web", engine.name.toLowerCase(), id], field: "semantic", score: 0.74, weight: 0.34 }]
            }));
        }
        return CompositeSearch.makeNode({
            id: "backend." + root.backendId,
            backendId: root.backendId,
            backendPriority: root.priority,
            kind: "backend",
            label: root.helpTitle,
            subtitle: root.helpDescription,
            icon: root.helpIcon,
            children: searchText ? children : [],
            evaluationProfile: { mode: "generic", strategies: ["exact", "prefix", "compact", "substring", "acronym"], scorePolicy: "backend" }
        });
    }

    function activate(result, action) {
        const metadata = result ? result.metadata || {} : {};
        const cmdAction = metadata.action || {};
        const engineId = metadata.engineId || cmdAction.engineId || (action && action.payload && action.payload.engineId);
        const engine = engineId ? root.engines[engineId] : null;
        if (!engine)
            return;

        const searchQuery = metadata.query || cmdAction.query || (action && action.payload && action.payload.query) || "";
        const encoded = encodeURIComponent(searchQuery);
        Quickshell.execDetached({ command: ["xdg-open", engine.url.replace("%1", encoded)] });
    }
}
