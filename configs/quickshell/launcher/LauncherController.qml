import QtQml
import "logic/QueryParsing.js" as QueryParsing
import "logic/ResultUtils.js" as ResultUtils
import "logic/Scoring.js" as Scoring

QtObject {
    id: root

    property string query: ""
    property var backends: []
    property var results: []
    property int selectedIndex: 0
    property int selectedActionIndex: 0
    property bool loading: false
    property int generation: 0
    property int maxResults: 12

    signal queryReplacementRequested(string text)

    function updateQuery(text) {
        generation += 1;
        const currentGeneration = generation;
        console.log("[Launcher] query:", text);

        query = text;
        results = [];
        selectedIndex = 0;
        selectedActionIndex = 0;
        loading = false;

        if (!text || text.trim().length === 0)
            return;

        collectResults(text, currentGeneration);
    }

    function collectResults(text, currentGeneration) {
        const parsed = QueryParsing.parse(text);
        let collected = [];
        const explicitWeb = QueryParsing.isExplicitFor(parsed, "web");

        for (const backend of backends) {
            if (!backend || !backend.enabled)
                continue;

            if (!explicitWeb && backendId(backend) === "web")
                continue;

            if (!backend.canHandle(text))
                continue;

            collected = collected.concat(searchBackend(backend, text, currentGeneration, parsed));
        }

        if (!explicitWeb && collected.length === 0 && !parsed.targetBackend) {
            const webBackend = backends.find(backend => backend && backend.enabled && backendId(backend) === "web");
            if (webBackend && webBackend.canHandle(text))
                collected = collected.concat(searchBackend(webBackend, text, currentGeneration, parsed));
        }

        if (currentGeneration !== generation)
            return;

        results = scoreAndSort(collected, text, parsed).slice(0, maxResults);
        console.log("[Launcher] final results:", JSON.stringify(results, null, 2));
    }

    function searchBackend(backend, text, currentGeneration, parsed) {
        try {
            const context = {
                generation: currentGeneration,
                parsedQuery: parsed,
                onResults: function(newResults) {
                    if (currentGeneration !== generation)
                        return;

                    mergeResults(newResults, backendId(backend), parsed);
                }
            };
            const backendResults = backend.search(text, context) || [];
            console.log("[Launcher] backend", backendId(backend), "returned", backendResults.length, "results");
            return ResultUtils.normalizeResults(backendResults, backendId(backend));
        } catch (error) {
            console.warn("[Launcher] backend failed:", backendId(backend), error);
            return [];
        }
    }

    function mergeResults(newResults, fallbackSource, parsed) {
        const merged = results.concat(ResultUtils.normalizeResults(newResults, fallbackSource));
        results = scoreAndSort(merged, query, parsed).slice(0, maxResults);
        console.log("[Launcher] merged async results:", JSON.stringify(results, null, 2));
    }

    function scoreAndSort(items, text, parsed) {
        return Scoring.sortResults(items, text, getBackendPriority, parsed || QueryParsing.parse(text));
    }

    function getBackendPriority(source) {
        const backend = backends.find(item => item && backendId(item) === source);
        return backend ? backend.priority : 0;
    }

    function backendId(backend) {
        return backend ? backend.backendId || "" : "";
    }

    function activateSelected() {
        const result = results[selectedIndex];
        if (!result) {
            console.warn("[Launcher] no selected result");
            return false;
        }

        const action = ResultUtils.defaultAction(result);
        return activateResult(result, action);
    }

    function activateResult(result, action) {
        if (!result || !action)
            return false;

        console.log("[Launcher] activate:", result.title, action.id);
        if (result.metadata && result.metadata.replaceQuery) {
            queryReplacementRequested(result.metadata.replaceQuery);
            return false;
        }

        const backend = backends.find(item => item && backendId(item) === result.source);
        if (!backend) {
            console.warn("[Launcher] missing backend for source:", result.source);
            return false;
        }

        try {
            backend.activate(result, action);
            return true;
        } catch (error) {
            console.warn("[Launcher] activation failed:", result.source, action.id, error);
            return false;
        }
    }

    function moveSelection(delta) {
        if (results.length === 0) {
            selectedIndex = 0;
            return;
        }

        selectedIndex = Math.max(0, Math.min(results.length - 1, selectedIndex + delta));
        selectedActionIndex = 0;
    }

    function reset() {
        query = "";
        results = [];
        selectedIndex = 0;
        selectedActionIndex = 0;
        loading = false;
        generation += 1;
    }
}
