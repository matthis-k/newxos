import QtQml
import "../logic/CommandTree.js" as CommandTree
import "../logic/Router.js" as Router

LauncherBackendBase {
    id: root

    property var treeRoots: []
    property var treePrefixes: []
    property var controller: null

    function results(query) {
        const prefixes = resolvePrefixes(query);
        const results = CommandTree.suggest(query, prefixes, root.treeRoots).map(result => {
            result.source = root.backendId;
            result.category = root.category;
            if (result.children && result.children.length > 0) {
                result.children.sort((a, b) => (b.relevance || 0) - (a.relevance || 0) || a.title.localeCompare(b.title));
            }
            return result;
        });

        const seen = {};
        const unique = [];
        for (const r of results) {
            const key = r.title || r.id;
            if (!seen[key]) {
                seen[key] = true;
                unique.push(r);
            }
        }
        return unique.slice(0, root.maxResults);
    }

    function resolvePrefixes(query) {
        const raw = String(query || "").trim();
        for (const prefix of root.treePrefixes || []) {
            if (prefix && raw.startsWith(prefix))
                return root.treePrefixes;
        }
        return [""];
    }

    function isEnabled(query) {
        if (!root.enabled)
            return false;
        for (const route of root.routes || []) {
            if (Router.routeMatches(query, route))
                return true;
        }
        return false;
    }
}
