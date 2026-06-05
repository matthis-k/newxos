import QtQuick
import QtQml
import Quickshell.Services.Pipewire
import qs.services
import "logic/CompositeSearch.js" as CompositeSearch
import "logic/DebugLogger.js" as DebugLogger

Item {
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
    property int maxTreeDepth: 4
    property var expandedNodeIds: ({})
    property var collapsedResultIndices: ({})
    property var lastQuery: null
    property var lastDirective: null
    property var lastEvaluatedRoot: null
    property var asyncBackendQueries: ({})
    property string resultsQuery: ""
    property bool debugEnabled: false

    // Tree navigation state
    property var currentTreeView: null
    property string currentTreeKey: ""
    property int treeVisualRow: -1
    readonly property bool inTree: currentTreeView !== null && treeVisualRow >= 0
    property var resultTreeViews: ({})
    property string activeNodeKey: ""

    signal queryReplacementRequested(string text)
    signal backendsChangeRequested(var backendIds)
    signal queryUpdateRequested(string text)
    signal resetRequested()
    signal resultsClearRequested()
    signal resultsRefreshRequested()
    signal collapseResultExpanded(int resultIndex)
    signal expandResultExpanded(int resultIndex)
    signal selectionResetRequested()
    signal asyncLoadingRefreshRequested()
    signal asyncBackendSearchStarted(var backend, string key, string text)
    signal asyncBackendResultsReceived(var backend, string key, string text, int generation, var update)
    signal searchRequested(string text, int generation)
    signal searchCompleted(string text, int generation, var output)
    signal resultsAvailable(string text, int generation, var rows, var output)
    signal treeSwitchRefreshRequested(int resultIndex)

    onQueryUpdateRequested: function(text) {
        generation += 1;
        query = text;
        selectedActionIndex = 0;
        loading = false;

        if (!text || text.trim().length === 0) {
            resultsClearRequested();
            lastQuery = null;
            lastDirective = null;
            lastEvaluatedRoot = null;
            return;
        }

        searchRequested(text, generation);
    }

    onResetRequested: function() {
        query = "";
        resultsClearRequested();
        loading = false;
        generation += 1;
        lastQuery = null;
        lastDirective = null;
        lastEvaluatedRoot = null;
        asyncBackendQueries = {};
    }

    onResultsClearRequested: function() {
        results = [];
        resultsQuery = "";
        selectionResetRequested();
    }

    onResultsRefreshRequested: function() {
        results = results.slice();
    }

    onSelectionResetRequested: function() {
        selectedIndex = -1;
        selectedActionIndex = 0;
        root.resetTreeNavigation();
    }

    onAsyncLoadingRefreshRequested: function() {
        loading = hasPendingAsyncBackends();
    }

    onAsyncBackendSearchStarted: function(backend, key, text) {
        var state = asyncBackendQueries[key] || {};
        state.pending = text;
        state.ready = "";
        asyncBackendQueries[key] = state;
        backend.pendingCompositeQuery = text;
        backend.compositeQuery = "";
        backend.applyStreamUpdate({ op: "clear" });
        asyncLoadingRefreshRequested();
    }

    onAsyncBackendResultsReceived: function(backend, key, text, requestGeneration, update) {
        if (requestGeneration !== root.generation || text !== root.query)
            return;

        var state = asyncBackendQueries[key] || {};
        state.pending = "";
        state.ready = text;
        asyncBackendQueries[key] = state;
        backend.pendingCompositeQuery = "";
        backend.compositeQuery = text;
        backend.applyStreamUpdate(update || []);
        asyncLoadingRefreshRequested();
        searchRequested(text, requestGeneration);
    }

    onSearchRequested: function(text, requestGeneration) {
        var output = searchNow(text, requestGeneration, true);
        searchCompleted(text, requestGeneration, output);
    }

    onSearchCompleted: function(text, requestGeneration, output) {
        if (!output || requestGeneration !== root.generation || text !== root.query)
            return;

        resultsAvailable(text, requestGeneration, sortRows(promoteContainerRows(output.rows), output.query, output.directive).slice(0, maxResults), output);
    }

    onResultsAvailable: function(text, requestGeneration, rows, output) {
        if (!output || requestGeneration !== root.generation || text !== root.query)
            return;

        lastQuery = output.query;
        lastDirective = output.directive;
        lastEvaluatedRoot = output.evaluatedRoot;
        setResults(rows, text);
    }

    function queryIsEmptyForSelection() {
        if (lastQuery && lastQuery.isEmpty !== undefined)
            return !!lastQuery.isEmpty;
        return !root.query || root.query.trim().length === 0;
    }

    function hasActivation(row) {
        return !!(row && (row.actions && row.actions.length > 0 || row.executable || row.switchActions || row.control || (row.filterable && row.children && row.children.length > 0)));
    }

    function isSelectable(row) {
        return root.hasActivation(row) && (root.queryIsEmptyForSelection() || (row.ownScore || 0) > 0 || !!row.ownVisible);
    }

    function serializeRow(row) {
        if (!row) return null;
        var out = {
            id: row.id || "",
            title: row.title || "",
            subtitle: row.subtitle || "",
            icon: row.icon || null,
            iconColor: row.iconColor ? String(row.iconColor) : null,
            depth: row.depth || 0,
            matchDepth: row.matchDepth === undefined ? row.depth || 0 : row.matchDepth,
            score: row.score || 0,
            ownScore: row.ownScore || 0,
            descendantScore: row.descendantScore || 0,
            ownVisible: !!row.ownVisible,
            source: row.source || row.backendId || "",
            kind: row.kind || "",
            executable: !!row.executable,
            dangerous: !!row.dangerous,
            selectable: root.isSelectable(row),
            breadcrumbs: row.breadcrumbs || [],
            breadcrumbText: row.breadcrumbText || "",
            filterable: !!row.filterable,
            lazy: !!row.lazy,
            alwaysExpanded: row.alwaysExpanded !== false,
            expandable: !!(row.children && row.children.length > 0) || !!row.lazy,
            switchState: row.switchState === undefined ? null : row.switchState,
            control: row.control || null,
            presentation: row.presentation || null,
            actions: (row.actions || []).map(function(a) {
                return { id: a.id || "", label: a.label || "", icon: a.icon || null, default: !!a.default };
            }),
            evidence: (row.evidence || []).map(function(e) {
                return {
                    strategy: e.strategy || "",
                    field: e.field || "",
                    fieldText: e.fieldText || "",
                    originNodeId: e.originNodeId || e.nodeId || "",
                    originKind: e.originKind || "self",
                    depth: e.depth === undefined ? 0 : e.depth,
                    tokenIndex: e.tokenIndex === undefined ? null : e.tokenIndex,
                    tokenIndexes: e.tokenIndexes || [],
                    coverageCount: e.coverageCount || 0,
                    exactness: e.exactness || e.strategy || "",
                    actionId: e.actionId || null,
                    actionRole: e.actionRole || null,
                    isExecutable: !!e.isExecutable,
                    score: e.score || 0,
                    weight: e.weight || 0,
                    effective: e.effective || 0,
                    kind: e.kind || "",
                    reason: e.reason || ""
                };
            })
        };
        if (row.children && row.children.length)
            out.children = row.children.map(root.serializeRow);
        if (row.switchActions) {
            out.switchActions = {};
            for (var k in row.switchActions)
                out.switchActions[k] = { id: row.switchActions[k].id, label: row.switchActions[k].label };
        }
        return out;
    }

    function findWordBoundaryMatch(text, token, startFrom) {
        if (startFrom === undefined) startFrom = 0;
        var idx = startFrom;
        while ((idx = text.indexOf(token, idx)) >= 0) {
            if (idx === 0) return idx;
            var prev = text[idx - 1];
            if (prev === " " || prev === "-" || prev === "_") return idx;
            idx += 1;
        }
        return -1;
    }

    function filterRowChildren(row, queryTokens) {
        if (!row || !row.filterable || !row.children || !queryTokens || queryTokens.length === 0)
            return;
        var parentTitle = (row.title || "").toLowerCase();
        var consumedParentPos = {};
        var consumedChildIdx = {};

        for (var ti = 0; ti < queryTokens.length; ti += 1) {
            var t = queryTokens[ti];
            var matched = false;

            // 1. Try parent word-boundary regions (depth 0)
            var searchPos = 0;
            while (!matched) {
                var pos = root.findWordBoundaryMatch(parentTitle, t, searchPos);
                if (pos < 0) break;
                if (!consumedParentPos[pos]) {
                    consumedParentPos[pos] = true;
                    matched = true;
                    break;
                }
                searchPos = pos + 1;
            }
            if (matched) continue;

            // 2. Try child word-boundary regions (depth 1). Siblings are separate paths,
            // so multiple children may consume the same token.
            for (var ci = 0; ci < row.children.length; ci += 1) {
                var childText = ((row.children[ci].title || "") + " " + (row.children[ci].subtitle || "")).toLowerCase();
                if (root.findWordBoundaryMatch(childText, t) >= 0) {
                    consumedChildIdx[String(ci)] = true;
                    matched = true;
                }
            }
            // 3. If still unmatched, token consumed by parent via substring (no child effect)
        }

        // If any child received a direct token match, show only those children
        var hasChildMatch = false;
        for (var ck in consumedChildIdx) { hasChildMatch = true; break; }
        if (hasChildMatch) {
            var keep = consumedChildIdx;
            row.children = row.children.filter(function(c, idx) { return keep[String(idx)]; });
        }
    }

    function hasSelectableDescendant(row) {
        return (row.children || []).some(function(c) { return root.isSelectable(c) || root.hasSelectableDescendant(c); });
    }

    function selectableRows(rows) {
        return (rows || []).filter(function(r) { return root.isSelectable(r) || root.hasSelectableDescendant(r); });
    }

    function shiftRowDepth(row, delta) {
        var out = Object.assign({}, row, { depth: Math.max(0, (row.depth || 0) + delta) });
        if (row.children && row.children.length)
            out.children = row.children.map(function(child) { return root.shiftRowDepth(child, delta); });
        return out;
    }

    function promoteContainerRows(rows) {
        var out = [];
        for (var i = 0; i < (rows || []).length; i += 1) {
            var row = rows[i];
            var children = row && row.children || [];
            if (row && !root.isSelectable(row) && children.length > 0 && !row.filterable) {
                var promoted = root.promoteContainerRows(children);
                for (var pi = 0; pi < promoted.length; pi += 1)
                    out.push(root.shiftRowDepth(promoted[pi], (row.depth || 0) - (promoted[pi].depth || 0)));
                continue;
            }
            if (row && children.length > 0)
                row = Object.assign({}, row, { children: root.promoteContainerRows(children) });
            if (row)
                out.push(row);
        }
        return out;
    }

    function sortRows(rows, queryInfo, directiveInfo) {
        if (directiveInfo && directiveInfo.active && queryInfo && queryInfo.isEmpty)
            return (rows || []).slice();
        return (rows || []).slice().sort(function(a, b) {
            var scoreDelta = (b.score || 0) - (a.score || 0);
            if (Math.abs(scoreDelta) > 0.0001) return scoreDelta;
            var switchDelta = (b.switchState !== null && b.switchState !== undefined ? 1 : 0) - (a.switchState !== null && a.switchState !== undefined ? 1 : 0);
            if (switchDelta !== 0) return switchDelta;
            var structuralDepthDelta = structuralDepth(a) - structuralDepth(b);
            if (structuralDepthDelta !== 0) return structuralDepthDelta;
            return effectiveMatchDepth(a) - effectiveMatchDepth(b);
        });
    }

    function structuralDepth(row) {
        return (row && row.breadcrumbs && row.breadcrumbs.length) || 0;
    }

    function effectiveMatchDepth(row) {
        if (!row)
            return 0;
        if (row.matchDepth !== undefined && row.matchDepth < 9999)
            return (row.depth || 0) + row.matchDepth;
        var ownScore = row.ownScore || 0;
        var children = row.children || [];
        var bestChildScore = 0;
        for (var i = 0; i < children.length; i += 1)
            bestChildScore = Math.max(bestChildScore, children[i].score || 0);
        if (bestChildScore > 0 && bestChildScore >= ownScore) {
            var bestDepth = 9999;
            for (var ci = 0; ci < children.length; ci += 1) {
                if (Math.abs((children[ci].score || 0) - bestChildScore) <= 0.0001)
                    bestDepth = Math.min(bestDepth, effectiveMatchDepth(children[ci]));
            }
            if (bestDepth < 9999)
                return bestDepth;
        }
        return row.depth || 0;
    }

    function querySearch(text) {
        var directive = CompositeSearch.parseDirective(text || "", backends || []);
        var query = CompositeSearch.tokenize(directive.searchRaw);
        var output = CompositeSearch.search(backends || [], text || "", stateForSearch(), Object.assign(searchOptions(), { showHidden: true }));
        var tokenStrs = (query.tokens || []).map(function(t) { return t.normalized; }).filter(Boolean);
        for (var ri = 0; ri < (output.rows || []).length; ri += 1)
            root.filterRowChildren(output.rows[ri], tokenStrs);
        var rows = sortRows(selectableRows(promoteContainerRows(output.rows)), query, directive);
        return JSON.stringify({
            version: 1,
            type: "search",
            query: {
                raw: query.raw,
                tokens: query.tokens.map(function(t) { return { raw: t.raw, normalized: t.normalized }; }),
                isEmpty: query.isEmpty,
                lastTokenEmpty: query.lastTokenEmpty
            },
            directive: {
                active: directive.active,
                prefix: directive.prefix || "",
                label: directive.label || "",
                backendIds: directive.backendIds || []
            },
            totalResults: rows.length,
            results: rows.map(root.serializeRow)
        });
    }

    function queryVisual(text) {
        var output = searchNow(text || "", generation, true);
        var rows = sortRows(promoteContainerRows(output.rows), output.query, output.directive).slice(0, maxResults);
        var previousResults = results;
        var previousQuery = query;
        var previousLastQuery = lastQuery;
        results = rows;
        query = text || "";
        lastQuery = output.query;
        var targets = root.navigationTargets().map(function(target) {
            return {
                key: target.key,
                title: target.row ? target.row.title || "" : "",
                parentIndex: target.parentIndex,
                treeDepth: target.treeDepth,
                selectable: target.row ? root.isSelectable(target.row) : false
            };
        });
        results = previousResults;
        query = previousQuery;
        lastQuery = previousLastQuery;
        return JSON.stringify({
            version: 1,
            type: "visual",
            query: {
                raw: output.query.raw,
                tokens: output.query.tokens.map(function(t) { return { raw: t.raw, normalized: t.normalized }; }),
                isEmpty: output.query.isEmpty,
                lastTokenEmpty: output.query.lastTokenEmpty
            },
            directive: {
                active: output.directive.active,
                prefix: output.directive.prefix || "",
                label: output.directive.label || "",
                backendIds: output.directive.backendIds || []
            },
            totalResults: rows.length,
            maxResults: maxResults,
            results: rows.map(root.serializeRow),
            navigationTargets: targets
        });
    }

    function queryComplete(text) {
        var output = searchNow(text || "", generation, true);
        var tokenStrs = (output.query && output.query.tokens || []).map(function(t) { return t.normalized; }).filter(Boolean);
        for (var ri = 0; ri < (output.rows || []).length; ri += 1)
            root.filterRowChildren(output.rows[ri], tokenStrs);
        var rows = sortRows(selectableRows(promoteContainerRows(output.rows)), output.query, output.directive);
        return JSON.stringify({
            version: 1,
            type: "complete",
            totalResults: rows.length,
            results: rows.slice(0, maxResults).map(root.serializeRow)
        });
    }

    function queryBackends() {
        var entries = (backends || []).filter(function(b) { return !!b; }).map(function(b) {
            var routes = [];
            if (typeof b.routes !== "undefined")
                routes = b.routes || [];
            var helpPrefixes = [];
            if (typeof b.helpPrefixes !== "undefined")
                helpPrefixes = b.helpPrefixes || [];
            return {
                id: b.backendId || "",
                name: b.name || "",
                description: b.description || "",
                enabled: !!b.enabled,
                priority: b.priority || 0,
                routes: routes,
                helpPrefixes: helpPrefixes,
                hasAsyncResults: typeof b.resultsAsync === "function",
                hasRootNode: typeof b.rootNode === "function",
                hasStreamUpdates: typeof b.applyStreamUpdate === "function"
            };
        });
        return JSON.stringify({
            version: 1,
            type: "backends",
            total: entries.length,
            backends: entries
        });
    }

    function queryRoutes(text) {
        var directive = CompositeSearch.parseDirective(text || "", backends || []);
        var rawQuery = text || "";
        var query = CompositeSearch.tokenize(directive.searchRaw);
        var participants = (backends || []).filter(function(b) {
            if (!b || !b.enabled)
                return false;
            if (typeof b.shouldParticipate === "function" && !b.shouldParticipate(rawQuery, directive, query))
                return false;
            return !directive.active || directive.backendIds.indexOf(b.backendId) >= 0;
        }).sort(function(a, b) { return (b.priority || 0) - (a.priority || 0); });
        return JSON.stringify({
            version: 1,
            type: "routes",
            query: text || "",
            directive: {
                active: directive.active,
                prefix: directive.prefix || "",
                label: directive.label || "",
                backendIds: directive.backendIds || []
            },
            participants: (participants || []).map(function(b) {
                return {
                    id: b.backendId || "",
                    name: b.name || "",
                    priority: b.priority || 0
                };
            })
        });
    }

    function queryEvidence(resultId) {
        var allResults = results || [];
        for (var i = 0; i < allResults.length; i += 1) {
            if (allResults[i].id === resultId || allResults[i].nodeId === resultId)
                return JSON.stringify({
                    version: 1,
                    type: "evidence",
                    resultId: resultId,
                    evidence: allResults[i].evidence || []
                });
        }
        return JSON.stringify({
            version: 1,
            type: "evidence",
            resultId: resultId,
            found: false,
            evidence: []
        });
    }

    function queryResult(resultId) {
        var allResults = results || [];
        for (var i = 0; i < allResults.length; i += 1) {
            if (allResults[i].id === resultId || allResults[i].nodeId === resultId)
                return JSON.stringify({
                    version: 1,
                    type: "result",
                    result: root.serializeRow(allResults[i])
                });
        }
        return JSON.stringify({
            version: 1,
            type: "result",
            found: false,
            result: null
        });
    }

    function queryState() {
        return JSON.stringify({
            version: 1,
            type: "state",
            query: query,
            selectedIndex: selectedIndex,
            childIndex: root.isInTree() ? treeVisualRow : -1,
            treeVisualRow: treeVisualRow,
            resultCount: results.length,
            loading: loading,
            backends: (backends || []).map(function(b) { return { id: b.backendId || "", name: b.name || "", enabled: !!b.enabled }; })
        });
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
            showHidden: showHidden,
            maxTreeDepth: maxTreeDepth
        };
    }

    function updateQuery(text) {
        queryUpdateRequested(text || "");
    }

    function searchNow(text, currentGeneration, includeAsync) {
        if (includeAsync)
            triggerAsyncBackends(text, currentGeneration);
        return CompositeSearch.search(backends || [], text || "", stateForSearch(), searchOptions());
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

            asyncBackendSearchStarted(backend, key, text);

            backend.resultsAsync(text, function(newResults) {
                asyncBackendResultsReceived(backend, key, text, currentGeneration, newResults || []);
            });
        }
    }

    function hasPendingAsyncBackends() {
        for (var key in asyncBackendQueries || {}) {
            if (asyncBackendQueries[key] && asyncBackendQueries[key].pending)
                return true;
        }
        return false;
    }

    function selectBestChild(row) {
        if (!row || !currentTreeView || currentTreeView.rows <= 0) return false;
        treeVisualRow = 0;
        var idx = currentTreeView.index(0, 0);
        currentTreeView.selectionModel.setCurrentIndex(idx, ItemSelectionModel.SelectCurrent);
        return true;
    }

    function setResults(newResults, sourceQuery) {
        var previousActiveNodeKey = activeNodeKey;
        var previousCollapsedByKey = {};
        for (var previousIndex = 0; previousIndex < results.length; previousIndex += 1) {
            var previousKey = root.rowKey(results[previousIndex]);
            if (previousKey)
                previousCollapsedByKey[previousKey] = !!collapsedResultIndices[previousIndex];
        }
        resultTreeViews = {};
        results = newResults || [];
        resultsQuery = sourceQuery || "";
        selectedActionIndex = 0;
        root.resetTreeNavigation();
        collapsedResultIndices = {};
        for (var i = 0; i < results.length; i += 1) {
            var key = root.rowKey(results[i]);
            if (key && previousCollapsedByKey[key] !== undefined) {
                if (previousCollapsedByKey[key])
                    collapsedResultIndices[i] = true;
            } else if (results[i].alwaysExpanded === false) {
                collapsedResultIndices[i] = true;
            }
        }
        var targets = root.navigationTargets();
        var preservedTarget = previousActiveNodeKey ? targets.find(function(target) { return target.key === previousActiveNodeKey; }) : null;
        root.applyNavigationTarget(preservedTarget || (targets.length > 0 ? targets[0] : null));
    }

    function registerResultTreeView(index, treeView) {
        if (index < 0 || !treeView) return;
        resultTreeViews[index] = treeView;
        if (index === selectedIndex && activeNodeKey) {
            var row = root.findTreeVisualRow(treeView, activeNodeKey);
            if (row >= 0) {
                currentTreeView = treeView;
                currentTreeKey = activeNodeKey;
                treeVisualRow = row;
                treeView.selectionModel.setCurrentIndex(treeView.index(row, 0), ItemSelectionModel.SelectCurrent);
            }
        }
    }

    function selectedResultTreeView() {
        return selectedIndex >= 0 ? resultTreeViews[selectedIndex] || null : null;
    }

    function backendId(backend) {
        return backend ? backend.backendId || "" : "";
    }

    function activateSelected(shiftPressed) {
        if (root.isInTree()) {
            if (root.currentTreeKey)
                return root.activateTreeRowByKey(root.currentTreeKey, null);
            return false;
        }
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

    function rowKey(row) {
        return row ? row.id || row.nodeId || "" : "";
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
            if (root.debugEnabled)
                DebugLogger.logExecute(result.id, action ? action.id : "", false, true);
            return true;
        } catch (error) {
            if (root.debugEnabled)
                DebugLogger.logError("Activation failed for " + result.id, error);
            return false;
        }
    }

    function applyIntent(result, intent) {
        if (!result || !intent)
            return false;
        switch (intent.type || "activate") {
        case "sequence": {
            var closeRequested = false;
            var steps = intent.steps || intent.actions || [];
            for (var si = 0; si < steps.length; si += 1) {
                if (root.applyIntent(result, steps[si]))
                    closeRequested = true;
            }
            return closeRequested;
        }
        case "close":
            return true;
        case "replace-query":
            queryReplacementRequested(intent.text || "");
            return false;
        case "noop":
            return false;
        case "activate":
        default: {
            var actions = result && result.actions ? result.actions : [];
            var defaultAction = actions.find(function(a) { return a.default; }) || actions[0] || null;
            var selectedAction = intent.action || defaultAction;
            if (selectedAction && selectedAction.intent)
                return root.applyIntent(result, selectedAction.intent);
            activateResult(result, selectedAction);
            return false;
        }
        }
    }

    function activateResultAction(result, actionId) {
        if (!result) {
            if (root.debugEnabled)
                DebugLogger.log("switch", "activateResultAction without result", { actionId: actionId || "" });
            return false;
        }
        var actions = result.actions || [];
        if (root.debugEnabled)
            DebugLogger.log("switch", "activateResultAction", {
                resultId: result.id || result.nodeId || "",
                title: result.title || "",
                source: result.source || result.backendId || "",
                actionId: actionId || "",
                actionIds: actions.map(function(action) { return action ? action.id || "" : ""; }),
                hasSwitchActions: !!result.switchActions,
                switchActionIds: result.switchActions ? Object.keys(result.switchActions) : [],
                switchState: result.switchState
            });
        for (var i = 0; i < actions.length; i += 1) {
            if (actions[i] && actions[i].id === actionId) {
                var activated = activateResult(result, actions[i]);
                if (root.debugEnabled)
                    DebugLogger.log("switch", "activateResultAction matched action list", {
                        resultId: result.id || result.nodeId || "",
                        actionId: actionId || "",
                        activated: activated,
                        payloadState: actions[i].payload ? actions[i].payload.state : undefined
                    });
                if (activated && result.switchActions)
                    refreshSwitchResult(result, actions[i]);
                return activated;
            }
        }
        if (result.switchActions && result.switchActions[actionId]) {
            var switchActivated = activateResult(result, result.switchActions[actionId]);
            if (root.debugEnabled)
                DebugLogger.log("switch", "activateResultAction matched switchActions", {
                    resultId: result.id || result.nodeId || "",
                    actionId: actionId || "",
                    activated: switchActivated,
                    payloadState: result.switchActions[actionId].payload ? result.switchActions[actionId].payload.state : undefined
                });
            if (switchActivated)
                refreshSwitchResult(result, result.switchActions[actionId]);
            return switchActivated;
        }
        if (root.debugEnabled)
            DebugLogger.log("switch", "activateResultAction no matching action", {
                resultId: result.id || result.nodeId || "",
                actionId: actionId || ""
            });
        return false;
    }

    function adjustSelectedValue(delta) {
        var result = selectedActionTarget();
        if (!result) {
            if (root.debugEnabled)
                DebugLogger.log("switch", "adjustSelectedValue without target", { delta: delta });
            return false;
        }

        if (result.control && adjustControlValue(result.control, delta))
            return true;

        var preferredIds = delta < 0
            ? ["off", "decrease", "decrement", "left"]
            : ["on", "increase", "increment", "right"];
        if (root.debugEnabled)
            DebugLogger.log("switch", "adjustSelectedValue", {
                delta: delta,
                preferredIds: preferredIds,
                inTree: root.isInTree(),
                activeNodeKey: root.activeNodeKey,
                targetId: result.id || result.nodeId || "",
                title: result.title || "",
                source: result.source || result.backendId || "",
                hasSwitchActions: !!result.switchActions,
                switchState: result.switchState
            });
        for (var i = 0; i < preferredIds.length; i += 1) {
            if (activateResultAction(result, preferredIds[i])) {
                if (root.isInTree() && root.currentTreeKey && result.switchActions && selectedIndex >= 0) {
                    var treeRow = root.findTreeRowData(root.currentTreeKey);
                    if (treeRow)
                        treeRow.switchState = result.switchState;
                    treeSwitchRefreshRequested(selectedIndex);
                    if (root.debugEnabled)
                        DebugLogger.log("switch", "adjustSelectedValue refreshed tree switch", {
                            rowKey: root.currentTreeKey,
                            switchState: result.switchState
                        });
                }
                return true;
            }
        }
        if (root.debugEnabled)
            DebugLogger.log("switch", "adjustSelectedValue no action activated", {
                delta: delta,
                targetId: result.id || result.nodeId || "",
                preferredIds: preferredIds
            });
        return false;
    }

    function toggleSelectedMute() {
        var result = selectedActionTarget();
        if (!result)
            return false;
        if (result.switchActions && (result.switchActions.toggle || result.switchActions.on || result.switchActions.off))
            return activateResultAction(result, "toggle");
        return false;
    }

    function adjustControlValue(control, delta) {
        if (!control || control.kind !== "slider")
            return false;

        var step = control.step || 5;
        if (control.target === "brightness") {
            Brightness.setPercent(alignedControlValue(Brightness.percent, delta, step, control.from || 0, control.to || 100));
            return true;
        }

        if (control.target === "pipewire") {
            var node = pipewireNodeById(control.nodeId);
            if (!node || !node.audio)
                return false;
            var current = Math.round((node.audio.volume || 0) * 100);
            var next = alignedControlValue(current, delta, step, control.from || 0, control.to || 150);
            node.audio.volume = next / 100;
            return true;
        }

        return false;
    }

    function alignedControlValue(current, delta, step, from, to) {
        var base = delta < 0 ? Math.floor(current / step) * step : Math.ceil(current / step) * step;
        if (Math.abs(base - current) < 0.0001)
            base += delta * step;
        return Math.max(from, Math.min(to, base));
    }

    function pipewireNodeById(nodeId) {
        for (const node of Pipewire.nodes.values || []) {
            if (String(node.id) === String(nodeId))
                return node;
        }
        return null;
    }

    function refreshSwitchResult(result, action) {
        var payload = action && action.payload || {};
        var state = payload.state;
        var previous = result ? result.switchState : undefined;
        if (state === true || state === false) {
            result.switchState = state;
        } else if (state === null) {
            result.switchState = result.switchState === true ? false : true;
        }
        if (root.debugEnabled)
            DebugLogger.log("switch", "refreshSwitchResult", {
                resultId: result ? result.id || result.nodeId || "" : "",
                actionId: action ? action.id || "" : "",
                payloadState: state,
                previousState: previous,
                nextState: result ? result.switchState : undefined
            });
        resultsRefreshRequested();
        Qt.callLater(function() {
            searchRequested(query, generation);
        });
    }

    function isRowSelectable(row) {
        return root.isSelectable(row);
    }

    function moveSelection(delta) {
        var targets = root.navigationTargets();
        if (targets.length === 0) {
            root.applyNavigationTarget(null);
            return;
        }

        var current = Math.max(0, targets.findIndex(function(target) { return target.key === root.activeNodeKey; }));
        var next = (current + delta + targets.length) % targets.length;
        root.applyNavigationTarget(targets[next]);
    }

    function navigationTargets() {
        var out = [];
        function visit(row, parentIndex, treeDepth) {
            if (!row) return;
            var children = row.children || [];
            if (root.isRowSelectable(row))
                out.push({ key: root.rowKey(row), row: row, parentIndex: parentIndex, treeDepth: treeDepth });
            if (root.collapsedResultIndices[parentIndex])
                return;
            for (var i = 0; i < children.length; i += 1)
                visit(children[i], parentIndex, treeDepth + 1);
        }
        for (var i = 0; i < results.length; i += 1)
            visit(results[i], i, 0);
        return out;
    }

    function applyNavigationTarget(target) {
        if (!target) {
            selectedIndex = -1;
            activeNodeKey = "";
            exitTree();
            return;
        }
        selectedIndex = target.parentIndex;
        selectedActionIndex = 0;
        activeNodeKey = target.key;
        if (target.treeDepth > 0) {
            currentTreeView = resultTreeViews[target.parentIndex] || null;
            currentTreeKey = target.key;
            treeVisualRow = currentTreeView ? root.findTreeVisualRow(currentTreeView, target.key) : -1;
            if (currentTreeView && treeVisualRow >= 0)
                currentTreeView.selectionModel.setCurrentIndex(currentTreeView.index(treeVisualRow, 0), ItemSelectionModel.SelectCurrent);
        } else {
            exitTree();
        }
    }

    function findTreeVisualRow(treeView, key) {
        if (!treeView || !treeView.model || !key) return -1;
        for (var row = 0; row < treeView.rows; row += 1) {
            var idx = treeView.index(row, 9);
            if (treeView.model.data(idx, "display") === key)
                return row;
        }
        return -1;
    }

    function reset() {
        resetRequested();
    }

    function resetTreeNavigation() {
        currentTreeView = null;
        currentTreeKey = "";
        treeVisualRow = -1;
        activeNodeKey = "";
    }

    function enterTree(result, treeView) {
        if (!result || !treeView || treeView.rows <= 0) return false;
        currentTreeView = treeView;
        treeVisualRow = 0;
        var idx = treeView.index(0, 0);
        treeView.selectionModel.setCurrentIndex(idx, ItemSelectionModel.SelectCurrent);
        return true;
    }

    function toggleCollapseResultTree() {
        if (selectedIndex >= 0) {
            if (root.isInTree()) {
                return root.treeCollapseSelected();
            } else {
                var collapseResult = results[selectedIndex];
                if (!collapseResult || !collapseResult.children || collapseResult.children.length === 0)
                    return false;
                collapsedResultIndices[selectedIndex] = true;
                collapseResultExpanded(selectedIndex);
            }
            return true;
        }
        return false;
    }

    function toggleExpandResultTree() {
        if (selectedIndex >= 0) {
            if (root.isInTree()) {
                return root.treeExpandSelected();
            } else {
                var expandResult = results[selectedIndex];
                if (!expandResult || !expandResult.children || expandResult.children.length === 0)
                    return false;
                delete collapsedResultIndices[selectedIndex];
                expandResultExpanded(selectedIndex);
            }
            return true;
        }
        return false;
    }

    function exitTree() {
        if (currentTreeView && currentTreeView.selectionModel)
            currentTreeView.selectionModel.clearCurrentIndex();
        currentTreeView = null;
        currentTreeKey = "";
        treeVisualRow = -1;
    }

    function isInTree() {
        return inTree;
    }

    function moveInTree(delta) {
        if (!currentTreeView) return;
        var newRow = treeVisualRow + delta;
        if (newRow < 0) {
            exitTree();
            return;
        }
        if (newRow >= currentTreeView.rows) {
            exitTree();
            if (results.length > 0)
                selectedIndex = (selectedIndex + 1) % results.length;
            selectedActionIndex = 0;
            return;
        }
        treeVisualRow = newRow;
        var idx = currentTreeView.index(newRow, 0);
        currentTreeView.selectionModel.setCurrentIndex(idx, ItemSelectionModel.SelectCurrent);
    }

    function treeCollapseSelected() {
        if (!currentTreeView) {
            if (root.debugEnabled)
                DebugLogger.log("switch", "treeCollapseSelected without tree", {});
            return false;
        }
        if (treeVisualRow >= 0) {
            if (currentTreeView.isExpanded(treeVisualRow)) {
                currentTreeView.collapse(treeVisualRow);
                if (root.debugEnabled)
                    DebugLogger.log("switch", "treeCollapseSelected collapsed current row", {
                        row: treeVisualRow,
                        key: currentTreeKey
                });
                return true;
            }
            var selectedTreeRow = root.findTreeRowData(currentTreeKey);
            if (selectedTreeRow && selectedTreeRow.switchActions) {
                if (root.debugEnabled)
                    DebugLogger.log("switch", "treeCollapseSelected switch leaf not handled", {
                        row: treeVisualRow,
                        key: currentTreeKey
                    });
                return false;
            }
            var idx = currentTreeView.index(treeVisualRow, 0);
            var parentIdx = currentTreeView.model.parent(idx);
            if (parentIdx.valid) {
                currentTreeView.collapse(parentIdx.row);
                currentTreeView.selectionModel.setCurrentIndex(parentIdx, ItemSelectionModel.SelectCurrent);
                treeVisualRow = parentIdx.row;
                currentTreeKey = currentTreeView.model.data(currentTreeView.index(parentIdx.row, 9), "display");
                if (root.debugEnabled)
                    DebugLogger.log("switch", "treeCollapseSelected collapsed parent row", {
                        row: treeVisualRow,
                        key: currentTreeKey
                    });
                return true;
            }
        }
        if (root.debugEnabled)
            DebugLogger.log("switch", "treeCollapseSelected not handled", {
                row: treeVisualRow,
                key: currentTreeKey
            });
        return false;
    }

    function treeExpandSelected() {
        if (!currentTreeView || treeVisualRow < 0) {
            if (root.debugEnabled)
                DebugLogger.log("switch", "treeExpandSelected without row", {
                    row: treeVisualRow,
                    key: currentTreeKey
                });
            return false;
        }
        var idx = currentTreeView.index(treeVisualRow, 0);
        var hasChildren = typeof currentTreeView.model.hasChildren === "function"
            ? currentTreeView.model.hasChildren(idx)
            : false;
        if (!hasChildren) {
            if (root.debugEnabled)
                DebugLogger.log("switch", "treeExpandSelected leaf not handled", {
                    row: treeVisualRow,
                    key: currentTreeKey
                });
            return false;
        }
        currentTreeView.expand(treeVisualRow);
        if (root.debugEnabled)
            DebugLogger.log("switch", "treeExpandSelected expanded current row", {
                row: treeVisualRow,
                key: currentTreeKey
            });
        return true;
    }

    function treeToggleSelected() {
        if (!currentTreeView || treeVisualRow < 0) return;
        if (currentTreeView.isExpanded(treeVisualRow))
            treeCollapseSelected();
        else
            treeExpandSelected();
    }

    function findTreeRowData(key) {
        if (!key) return null;
        for (var ri = 0; ri < results.length; ri += 1) {
            var found = root.findInChildren(results[ri], key);
            if (found) return found;
        }
        return null;
    }

    function findInChildren(row, key) {
        if (!row) return null;
        if (row.id === key || row.nodeId === key) return row;
        var children = row.children || [];
        for (var i = 0; i < children.length; i += 1) {
            var found = root.findInChildren(children[i], key);
            if (found) return found;
        }
        return null;
    }

    function findParentResultByKey(key) {
        for (var i = 0; i < results.length; i += 1) {
            if (root.findInChildren(results[i], key))
                return results[i];
        }
        return null;
    }

    function loadLazyChildren(key) {
        var treeRow = root.findTreeRowData(key);
        if (!treeRow || !treeRow.lazy) return;
        var parentResult = root.findParentResultByKey(key);
        if (!parentResult) return;
        var sourceId = treeRow.source || parentResult.source || parentResult.backendId || "";
        var backend = null;
        for (var i = 0; i < (backends || []).length; i += 1) {
            if (backends[i] && backendId(backends[i]) === sourceId) {
                backend = backends[i];
                break;
            }
        }
        if (!backend || typeof backend.scanDirectory !== "function") return;
        var path = (treeRow.meta && treeRow.meta.path) || "";
        if (!path && treeRow.id && treeRow.id.indexOf("file:") === 0)
            path = treeRow.id.slice(5);
        if (!path) return;
        backend.scanDirectory(path, function(children) {
            treeRow.children = children;
            treeRow.lazy = false;
            root.expandedNodeIds[treeRow.nodeId || treeRow.id] = true;
            root.searchRequested(root.query, root.generation);
        });
    }

    function activateTreeRowByKey(key, actionId) {
        var row = root.findTreeRowData(key);
        if (!row) return false;
        var parent = root.findParentResultByKey(key);
        var target = Object.assign({}, row, {
            source: row.source || (parent ? parent.source || parent.backendId : ""),
            category: row.category || (parent ? parent.category : "")
        });
        if (actionId) {
            var activated = root.activateResultAction(target, actionId);
            if (activated && target.switchActions && selectedIndex >= 0) {
                row.switchState = target.switchState;
                treeSwitchRefreshRequested(selectedIndex);
            }
            return activated;
        }
        return root.applyIntent(target, target.enter);
    }

    function treeActivateCurrent() {
        if (root.currentTreeKey)
            return root.activateTreeRowByKey(root.currentTreeKey, null);
        return false;
    }

    function selectedActionTarget() {
        if (root.isInTree() && root.currentTreeKey) {
            var treeRow = root.findTreeRowData(root.currentTreeKey);
            if (treeRow) {
                var parent = results[selectedIndex];
                return Object.assign({}, treeRow, {
                    source: treeRow.source || (parent ? parent.source || parent.backendId : ""),
                    category: treeRow.category || (parent ? parent.category : "")
                });
            }
        }
        return selectedResult();
    }
}
