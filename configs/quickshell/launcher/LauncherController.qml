import QtQml
import "logic/QueryParsing.js" as QueryParsing
import "logic/ResultUtils.js" as ResultUtils
import "logic/Router.js" as Router
import "logic/Scoring.js" as Scoring
import "logic/SearchEngine.js" as SearchEngine
import "logic/DebugLogger.js" as DebugLogger
import "logic/EvidenceScorer.js" as EvidenceScorer

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
    signal backendsChangeRequested(var backendIds)

    function debugComplete(text) {
        generation += 1;
        var currentGeneration = generation;
        var matches = Router.matches(text, backends);
        var output = [];

        for (var mi = 0; mi < matches.length; mi += 1) {
            output.push({
                backend: backendId(matches[mi].backend),
                route: matches[mi].route ? matches[mi].route.mode : "",
                prefix: matches[mi].prefix,
                results: collectBackend(matches[mi], text, currentGeneration)
            });
        }

        if (output.length === 0) {
            var fallbackMatches = Router.fallbacks(text, backends);
            for (var fi2 = 0; fi2 < fallbackMatches.length; fi2 += 1) {
                output.push({
                    backend: backendId(fallbackMatches[fi2].backend),
                    route: fallbackMatches[fi2].route ? fallbackMatches[fi2].route.mode : "",
                    prefix: fallbackMatches[fi2].prefix,
                    results: collectBackend(fallbackMatches[fi2], text, currentGeneration)
                });
            }
        }

        return JSON.stringify(output, null, 2);
    }

    function debugCompleteBackend(backendName, text) {
        generation += 1;
        var backend = null;
        for (var bi = 0; bi < (backends || []).length; bi += 1) {
            var item = backends[bi];
            if (item && backendId(item) === backendName) {
                backend = item;
                break;
            }
        }
        if (!backend)
            return JSON.stringify({ error: "backend not found", backend: backendName });

        var route = (backend.routes || [])[0] || { prefixes: [""], mode: "ambient", stripPrefix: false };
        var match = { backend: backend, route: route, prefix: "", routedText: text || "" };
        return JSON.stringify(collectBackend(match, text || "", generation), null, 2);
    }

    function debugRoutes(text) {
        var output = Router.matches(text, backends).map(function(match) {
            return {
                backend: backendId(match.backend),
                mode: match.route ? match.route.mode : "",
                prefix: match.prefix,
                routedText: match.routedText
            };
        });
        return JSON.stringify(output, null, 2);
    }

    function debugSearch(queryText) {
        var parsed = SearchEngine.parseQuery(queryText);
        var result = SearchEngine.debugSearch(backends, queryText, { maxResults: maxResults });
        return JSON.stringify(result, null, 2);
    }

    function debugEvidence(resultId) {
        for (var ri = 0; ri < results.length; ri += 1) {
            if (results[ri].id === resultId) {
                var ev = results[ri].evidence;
                if (ev)
                    return JSON.stringify(ev, null, 2);
                return JSON.stringify({ error: "no evidence for result" });
            }
        }
        return JSON.stringify({ error: "result not found", id: resultId });
    }

    function updateQuery(text) {
        generation += 1;
        var currentGeneration = generation;

        query = text;
        results = [];
        selectedIndex = -1;
        selectedActionIndex = 0;
        loading = false;

        if (!text || text.trim().length === 0)
            return;

        collectResults(text, currentGeneration);
    }

    function collectResults(text, currentGeneration) {
        var parsed = QueryParsing.parse(text);
        var engineResults = SearchEngine.search(backends, parsed, {
            profile: "general",
            maxResults: maxResults * 2
        });

        if (currentGeneration !== generation)
            return;

        var normalized = engineResults.map(function(c) { return ResultUtils.searchCandidateToResult(c); }).filter(Boolean);

        setResults(normalized.slice(0, maxResults));
    }

    function collectBackend(match, text, currentGeneration) {
        var backend = match.backend;
        try {
            if (backend.resultsAsync) {
                backend.resultsAsync(text, function(newResults) {
                    if (currentGeneration !== generation)
                        return;
                    mergeResults(newResults, backendId(backend));
                });
                return [];
            }

            var backendResults = backend.results ? backend.results(text) : [];
            return ResultUtils.normalizeResults(backendResults, backendId(backend));
        } catch (error) {
            console.warn("launcher backend results failed", backendId(backend), error);
            return [];
        }
    }

    function scoreAndSort(items, text) {
        var parsed = QueryParsing.parse(text);
        return Scoring.sortResults(items, text, getBackendPriority, parsed);
    }

    function getBackendPriority(source) {
        for (var bi = 0; bi < (backends || []).length; bi += 1) {
            var item = backends[bi];
            if (item && backendId(item) === source)
                return item.priority || 0;
        }
        return 0;
    }

    function setResults(newResults) {
        results = newResults || [];
        selectedIndex = results.length === 1 ? 0 : -1;
        selectedActionIndex = 0;
    }

    function mergeResults(newResults, fallbackSource) {
        var merged = results.concat(ResultUtils.normalizeResults(newResults, fallbackSource));
        var parsed = QueryParsing.parse(query);
        var engineResults = SearchEngine.search(backends, parsed, {
            profile: "general",
            maxResults: maxResults * 2
        });
        setResults(engineResults.slice(0, maxResults));
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

        if (result.dangerous) {
            var safe = EvidenceScorer.isSafeToExecute({ score: result.score, dangerous: true });
            if (!safe)
                return false;
        }

        if (result.metadata && result.metadata.replaceQuery) {
            queryReplacementRequested(result.metadata.replaceQuery);
            return false;
        }

        var backend = null;
        for (var bi = 0; bi < (backends || []).length; bi += 1) {
            var item = backends[bi];
            if (item && backendId(item) === result.source) {
                backend = item;
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
    }
}
