import QtQml
import "logic/CompositeSearch.js" as CompositeSearch
import "logic/ResultUtils.js" as ResultUtils
import "logic/DebugLogger.js" as DebugLogger

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
    property real visibilityThreshold: 0.18
    property bool includePath: true
    property string flattenMode: "hybrid"
    property bool showHidden: false
    property var expandedNodeIds: ({})
    property var lastQuery: null
    property var lastDirective: null
    property var lastEvaluatedRoot: null
    property var asyncBackendQueries: ({})

    signal queryReplacementRequested(string text)
    signal backendsChangeRequested(var backendIds)

    function debugComplete(text) {
        updateQuery(text || "");
        return JSON.stringify(results, null, 2);
    }

    function debugCompleteBackend(backendName, text) {
        var selected = [];
        for (var i = 0; i < (backends || []).length; i += 1) {
            if (backends[i] && backends[i].backendId === backendName)
                selected.push(backends[i]);
        }
        var output = CompositeSearch.search(selected, text || "", stateForSearch(), searchOptions());
        return JSON.stringify(output.rows, null, 2);
    }

    function debugRoutes(text) {
        var directive = CompositeSearch.parseDirective(text || "", backends || []);
        return JSON.stringify(directive, null, 2);
    }

    function debugSearch(text) {
        var output = CompositeSearch.search(backends || [], text || "", stateForSearch(), searchOptions());
        return JSON.stringify({ directive: output.directive, query: output.query, rows: output.rows }, null, 2);
    }

    function debugBenchmark(arg) {
        var config = parseBenchmarkConfig(arg);
        var queries = config.queries.slice(0, 32);
        var iterations = Math.max(1, Math.min(config.iterations, 20));
        var warmups = Math.max(0, Math.min(config.warmups, 5));
        var samples = [];
        var totalMs = 0;
        var maxMs = 0;

        for (var wi = 0; wi < warmups; wi += 1) {
            for (var wq = 0; wq < queries.length; wq += 1)
                CompositeSearch.search(backends || [], queries[wq], stateForSearch(), Object.assign(searchOptions(), { trace: true }));
        }

        for (var i = 0; i < iterations; i += 1) {
            for (var qi = 0; qi < queries.length; qi += 1) {
                var start = Date.now();
                var output = CompositeSearch.search(backends || [], queries[qi], stateForSearch(), Object.assign(searchOptions(), { trace: true }));
                var elapsed = Date.now() - start;
                totalMs += elapsed;
                maxMs = Math.max(maxMs, elapsed);
                samples.push({
                    query: queries[qi],
                    wallMs: elapsed,
                    timings: output.timings || {},
                    rows: output.rows.length,
                    top: output.rows.length > 0 ? output.rows[0].title : ""
                });
            }
        }

        var count = Math.max(1, iterations * queries.length);
        var summary = {
            iterations: iterations,
            warmups: warmups,
            queryCount: queries.length,
            avgMs: totalMs / count,
            maxMs: maxMs,
            samples: samples
        };
        console.log("launcher benchmark " + JSON.stringify({ avgMs: summary.avgMs, maxMs: summary.maxMs, count: count }));
        return JSON.stringify(summary, null, 2);
    }

    function parseBenchmarkConfig(arg) {
        var defaults = {
            iterations: 3,
            warmups: 1,
            queries: ["z", "ze", "zen", "zen ", "zen priv", "zen win", ":wifi", ":wifi ", ":wifi on", ":wifi off", ":db wifi", ":zen", "@app zen", "wifi", "db wifi"]
        };
        if (!arg)
            return defaults;
        try {
            var parsed = JSON.parse(arg);
            if (Array.isArray(parsed))
                defaults.queries = parsed.map(function(x) { return String(x); });
            else if (parsed && typeof parsed === "object") {
                if (Array.isArray(parsed.queries))
                    defaults.queries = parsed.queries.map(function(x) { return String(x); });
                if (parsed.iterations !== undefined)
                    defaults.iterations = Number(parsed.iterations);
                if (parsed.warmups !== undefined)
                    defaults.warmups = Number(parsed.warmups);
            }
        } catch (error) {
            defaults.queries = [String(arg)];
        }
        return defaults;
    }

    function debugEvidence(resultId) {
        for (var i = 0; i < results.length; i += 1) {
            if (results[i].id === resultId || results[i].nodeId === resultId)
                return JSON.stringify(results[i].evidence || [], null, 2);
        }
        return JSON.stringify({ error: "result not found", id: resultId });
    }

    function stateForSearch() {
        return {
            selectedNodeId: selectedResult() ? selectedResult().nodeId : null,
            expandedNodeIds: expandedNodeIds || {}
        };
    }

    function searchOptions() {
        return {
            visibilityThreshold: visibilityThreshold,
            includePath: includePath,
            flattenMode: flattenMode,
            showHidden: showHidden
        };
    }

    function updateQuery(text) {
        generation += 1;
        query = text;
        selectedActionIndex = 0;
        loading = false;

        if (!text || text.trim().length === 0) {
            results = [];
            selectedIndex = -1;
            lastQuery = null;
            lastDirective = null;
            lastEvaluatedRoot = null;
            return;
        }

        collectResults(text, generation);
    }

    function collectResults(text, currentGeneration) {
        triggerAsyncBackends(text, currentGeneration);
        var output = CompositeSearch.search(backends || [], text || "", stateForSearch(), searchOptions());
        if (currentGeneration !== generation)
            return;

        lastQuery = output.query;
        lastDirective = output.directive;
        lastEvaluatedRoot = output.evaluatedRoot;
        setResults(output.rows.slice(0, maxResults));
    }

    function triggerAsyncBackends(text, currentGeneration) {
        var directive = CompositeSearch.parseDirective(text || "", backends || []);
        var parsedQuery = CompositeSearch.tokenize(directive.searchRaw || "");

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

            state.pending = text;
            state.ready = "";
            asyncBackendQueries[key] = state;
            backend.pendingCompositeQuery = text;
            backend.compositeQuery = "";
            backend.compositeResults = [];
            loading = true;

            backend.resultsAsync(text, function(newResults) {
                if (currentGeneration !== generation)
                    return;
                let callbackKey = backend.backendId || String(i);
                let callbackState = asyncBackendQueries[callbackKey] || {};
                callbackState.pending = "";
                callbackState.ready = text;
                asyncBackendQueries[callbackKey] = callbackState;
                backend.pendingCompositeQuery = "";
                backend.compositeQuery = text;
                backend.compositeResults = newResults || [];
                loading = false;
                collectResults(text, currentGeneration);
            });
        }
    }

    function collectBackend(match, text, currentGeneration) {
        return [];
    }

    function scoreAndSort(items, text) {
        return items || [];
    }

    function getBackendPriority(source) {
        for (var i = 0; i < (backends || []).length; i += 1) {
            if (backends[i] && backends[i].backendId === source)
                return backends[i].priority || 0;
        }
        return 0;
    }

    function setResults(newResults) {
        results = newResults || [];
        selectedIndex = results.length > 0 ? Math.max(0, Math.min(selectedIndex, results.length - 1)) : -1;
        if (results.length === 1)
            selectedIndex = 0;
        selectedActionIndex = 0;
    }

    function mergeResults(newResults, fallbackSource) {
        collectResults(query, generation);
    }

    function backendId(backend) {
        return backend ? backend.backendId || "" : "";
    }

    function activateSelected(shiftPressed) {
        var result = selectedResult();
        if (!result)
            return false;
        return applyIntent(result, shiftPressed ? result.shiftEnter : result.enter);
    }

    function completeSelected() {
        var result = selectedResult();
        if (!result)
            return false;
        if (typeof result.onComplete === "function") {
            var closeRequested = result.onComplete({
                query: root.query,
                replaceQuery: function(text) {
                    root.query = text;
                    root.updateQuery(text);
                },
                setBackends: function(backendIds) {
                    root.backendsChangeRequested(backendIds);
                }
            });
            return closeRequested === true;
        }
        return applyIntent(result, result.shiftEnter);
    }

    function selectedResult() {
        return selectedIndex >= 0 ? results[selectedIndex] : null;
    }

    function activateResult(result, action) {
        if (!result || !action)
            return false;

        if (result.metadata && result.metadata.replaceQuery) {
            queryReplacementRequested(result.metadata.replaceQuery);
            return false;
        }

        var backend = null;
        for (var i = 0; i < (backends || []).length; i += 1) {
            if (backends[i] && backendId(backends[i]) === result.source) {
                backend = backends[i];
                break;
            }
        }
        if (!backend)
            return false;

        try {
            backend.activate(result, action);
            DebugLogger.logExecute(result.id, action ? action.id : "", false, true);
            return true;
        } catch (error) {
            DebugLogger.logError("Activation failed for " + result.id, error);
            return false;
        }
    }

    function applyIntent(result, intent) {
        if (!result || !intent)
            return false;
        switch (intent.type || "activate") {
        case "replace-query":
            queryReplacementRequested(intent.text || "");
            return false;
        case "noop":
            return false;
        case "activate":
        default:
            return activateResult(result, intent.action || ResultUtils.defaultAction(result));
        }
    }

    function activateResultAction(result, actionId) {
        if (!result)
            return false;
        var actions = result.actions || [];
        for (var i = 0; i < actions.length; i += 1) {
            if (actions[i] && actions[i].id === actionId) {
                var activated = activateResult(result, actions[i]);
                if (activated && result.switchActions)
                    refreshSwitchResult(result, actions[i]);
                return activated;
            }
        }
        return false;
    }

    function refreshSwitchResult(result, action) {
        var payload = action && action.payload || {};
        var state = payload.state;
        if (state === true || state === false) {
            result.switchState = state;
        } else if (state === null) {
            result.switchState = result.switchState === true ? false : true;
        }
        results = results.slice();
        Qt.callLater(function() {
            collectResults(query, generation);
        });
    }

    function moveSelection(delta) {
        if (results.length === 0) {
            selectedIndex = -1;
            return;
        }
        var baseIndex = selectedIndex < 0 ? (delta > 0 ? -1 : results.length) : selectedIndex;
        selectedIndex = Math.max(0, Math.min(results.length - 1, baseIndex + delta));
        selectedActionIndex = 0;
    }

    function reset() {
        query = "";
        results = [];
        selectedIndex = -1;
        selectedActionIndex = 0;
        loading = false;
        generation += 1;
        lastQuery = null;
        lastDirective = null;
        lastEvaluatedRoot = null;
        asyncBackendQueries = {};
    }
}
