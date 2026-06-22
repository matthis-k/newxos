import QtQuick
import QtQml
import "../logic/"
import "../logic/RoutingTree.js" as RoutingTree

Item {
    id: root

    property var controller: null
    property string query: ""
    property var backends: []
    property var routingTree: null
    property int maxResults: 12
    property bool loading: false
    property int generation: 0
    property int asyncGeneration: 0
    property int queryRevision: 0
    property var asyncBackendQueries: ({})

    signal resultsClearRequested()
    signal searchStarted(string text, int generation, int revision)
    signal searchCompleted(string text, int generation, int revision, var output)
    signal resultsAvailable(string text, int generation, int revision, var rows, var output)

    Timer {
        id: searchTimer
        interval: 40
        repeat: false
        onTriggered: root.startSearch(root.query, root.generation, true)
    }

    function updateQuery(text) {
        queryRevision += 1;
        generation += 1;
        query = text || "";
        if (controller)
            controller.selectedActionIndex = 0;

        if (!query || query.trim().length === 0) {
            resultsClearRequested();
            if (controller)
                controller.clearSearchOutputState();
            searchTimer.stop();
            return;
        }

        searchTimer.restart();
    }

    function reset() {
        searchTimer.stop();
        query = "";
        resultsClearRequested();
        loading = false;
        generation += 1;
        if (controller)
            controller.clearSearchOutputState();
        asyncBackendQueries = {};
        asyncGeneration += 1;
    }

    function requestSearch(text, requestGeneration) {
        startSearch(text || "", requestGeneration, false);
    }

    function startSearch(text, requestGeneration, bumpAsyncGeneration) {
        var ag = bumpAsyncGeneration ? (root.asyncGeneration += 1) : root.asyncGeneration;
        var revision = root.queryRevision;
        triggerAsyncBackends(text, requestGeneration);
        searchStarted(text, requestGeneration, revision);
        Engine.searchAsync(backends || [], text || "", stateForSearch(), searchOptions(),
            function() { return root.generation === requestGeneration && root.asyncGeneration === ag; },
            function(output) {
                if (!output)
                    return;
                if (requestGeneration !== root.generation || text !== root.query)
                    return;

                output.queryRevision = revision;
                root.searchCompleted(text, requestGeneration, revision, output);
                root.resultsAvailable(text, requestGeneration, revision, output.rows.slice(0, maxResults), output);
            }
        );
    }

    function stateForSearch() {
        return controller ? controller.stateForSearch() : {};
    }

    function searchOptions() {
        return controller ? controller.searchOptions() : {};
    }

    function triggerAsyncBackends(text, currentGeneration) {
        var route = RoutingTree.routeQuery(root.routingTree, text || "");
        var directive = route && route.endpoints && route.endpoints.length > 0
            ? Engine.buildDirectiveFromRoute(text || "", route, backends || [])
            : Tokenize.parseDirective(text || "", backends || []);
        var parsedQuery = Tokenize.tokenize(directive.searchRaw || "");

        for (let i = 0; i < (backends || []).length; i += 1) {
            let backend = backends[i];
            if (!backend || !backend.enabled || typeof backend.resultsAsync !== "function")
                continue;
            if (typeof backend.shouldParticipate === "function" && !backend.shouldParticipate(text || "", directive, parsedQuery))
                continue;
            if (directive.active && directive.backendIds.indexOf(backend.backendId) < 0)
                continue;

            let key = backend.backendId || String(i);
            let state = asyncBackendQueries[key] || {};
            if (state.ready === text || state.pending === text)
                continue;

            beginAsyncBackendSearch(backend, key, text);

            backend.resultsAsync(text, function(newResults) {
                receiveAsyncBackendResults(backend, key, text, currentGeneration, newResults || []);
            });
        }
    }

    function beginAsyncBackendSearch(backend, key, text) {
        var state = asyncBackendQueries[key] || {};
        state.pending = text;
        state.ready = "";
        asyncBackendQueries[key] = state;
        backend.pendingCompositeQuery = text;
        backend.compositeQuery = "";
        backend.applyStreamUpdate({ op: "clear" });
        refreshLoading();
    }

    function receiveAsyncBackendResults(backend, key, text, requestGeneration, update) {
        if (requestGeneration !== root.generation || text !== root.query)
            return;

        var state = asyncBackendQueries[key] || {};
        state.pending = "";
        state.ready = text;
        asyncBackendQueries[key] = state;
        backend.pendingCompositeQuery = "";
        backend.compositeQuery = text;
        backend.applyStreamUpdate(update || []);
        refreshLoading();
        root.asyncGeneration += 1;
        requestSearch(text, requestGeneration);
    }

    function refreshLoading() {
        loading = hasPendingAsyncBackends();
    }

    function hasPendingAsyncBackends() {
        for (var key in asyncBackendQueries || {}) {
            if (asyncBackendQueries[key] && asyncBackendQueries[key].pending)
                return true;
        }
        return false;
    }
}
