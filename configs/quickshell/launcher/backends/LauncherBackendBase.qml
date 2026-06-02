import QtQml
import "../logic/CompositeSearch.js" as CompositeSearch
import "../logic/QueryParsing.js" as QueryParsing
import "../logic/Router.js" as Router

QtObject {
    id: root

    property string backendId: ""
    property string name: ""
    property string category: ""
    property string helpTitle: name
    property string helpDescription: ""
    property string helpIcon: "system-search"
    property var helpPrefixes: []
    property bool enabled: true
    property int priority: 0
    property int maxResults: 5
    property var routes: []
    property var controller: null
    property string activeQuery: ""
    property int activeGeneration: 0

    signal backendError(string message)

    function beginSearch(query, generation) {
        if (root.activeQuery && root.activeGeneration !== generation)
            root.cancelSearch(root.activeQuery, root.activeGeneration);
        root.activeQuery = query || "";
        root.activeGeneration = generation || 0;
    }

    function finishSearch(query, generation) {
        if (generation !== undefined && generation !== root.activeGeneration)
            return;
        root.activeQuery = "";
        root.activeGeneration = 0;
    }

    function cancelSearch(query, generation) {
        root.activeQuery = "";
        root.activeGeneration = 0;
    }

    function activate(result, action) {
    }

    function actionDto(id, label, payload) {
        return CompositeSearch.makeAction(id, label, payload || {});
    }

    function nodeDto(options) {
        const opts = options || {};
        return CompositeSearch.makeNode(Object.assign({
            backendId: root.backendId,
            kind: "backend-result",
            icon: root.helpIcon || "system-search"
        }, opts));
    }

    function backendRootDto(children, options) {
        const opts = options || {};
        return CompositeSearch.makeNode(Object.assign({
            id: "backend." + root.backendId,
            backendId: root.backendId,
            backendPriority: root.priority,
            kind: "backend",
            label: root.helpTitle || root.name || root.backendId,
            subtitle: root.helpDescription || "",
            icon: root.helpIcon || "system-search",
            children: children || [],
            evaluationProfile: { mode: "generic", strategies: ["exact", "prefix", "compact", "substring", "acronym"], scorePolicy: "backend" }
        }, opts));
    }

    function queryText(query) {
        const parsed = QueryParsing.parse(query);
        for (const route of root.routes || []) {
            if (Router.routeMatches(query, route)) {
                const routed = Router.extractText(query, route);
                if (route.pattern)
                    return routed;
                if (parsed.explicit && parsed.targetBackend === root.backendId)
                    return parsed.text || "";
                return routed;
            }
        }
        return query || "";
    }

}
