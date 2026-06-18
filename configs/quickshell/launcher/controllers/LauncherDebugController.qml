import QtQuick
import QtQml
import "../logic/"

Item {
    id: root

    property var controller: null

    function serializeRow(row) {
        if (!row) return null;
        var out = {
            id: row.id || "",
            nodeId: row.nodeId || "",
            title: row.title || "",
            subtitle: row.subtitle || "",
            icon: row.icon || null,
            iconColor: row.iconColor ? String(row.iconColor) : null,
            depth: row.depth || 0,
            matchDepth: row.matchDepth === undefined ? row.depth || 0 : row.matchDepth,
            score: row.score || 0,
            ownScore: row.ownScore || 0,
            inheritedScore: row.inheritedScore || 0,
            descendantScore: row.descendantScore || 0,
            ownVisible: !!row.ownVisible,
            scoreBundle: row.scoreBundle ? ScoreBundle.toDebug(row.scoreBundle) : null,
            placement: row.placement || "",
            presentationContext: row.presentationContext || null,
            source: row.source || row.backendId || "",
            kind: row.kind || "",
            executable: !!row.executable,
            dangerous: !!row.dangerous,
            risk: row.risk || null,
            selectable: controller.isSelectable(row),
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
        if (row.recipes) {
            out.recipes = {};
            for (var rk in row.recipes) {
                if (Array.isArray(row.recipes[rk]))
                    out.recipes[rk] = row.recipes[rk].slice();
            }
        }
        if (row.interactions) {
            out.interactions = {};
            for (var ik in row.interactions) {
                var entry = row.interactions[ik];
                if (entry && typeof entry === "object")
                    out.interactions[ik] = { label: entry.label || "", recipe: (entry.recipe || []).slice() };
            }
        }
        return out;
    }

    function serializeRowsForQuery(rows, queryInfo) {
        var previousLastQuery = controller.lastQuery;
        controller.lastQuery = queryInfo || null;
        var out = (rows || []).map(root.serializeRow);
        controller.lastQuery = previousLastQuery;
        return out;
    }

    function resolveQueryArg(text) {
        if (!text) return text || "";
        var trimmed = text.trim();
        if (trimmed.length > 0 && (trimmed[0] === "{" || trimmed[0] === "[")) {
            try {
                var parsed = JSON.parse(trimmed);
                if (typeof parsed === "object" && parsed.query !== undefined)
                    return String(parsed.query);
            } catch (e) {}
        }
        return text;
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
                Engine.search(controller.backends || [], queries[wq], controller.stateForSearch(), Object.assign(controller.searchOptions(), { trace: true }));
        }

        for (var i = 0; i < iterations; i += 1) {
            for (var qi = 0; qi < queries.length; qi += 1) {
                var start = Date.now();
                var output = Engine.search(controller.backends || [], queries[qi], controller.stateForSearch(), Object.assign(controller.searchOptions(), { trace: true }));
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

    function debugVisualRows(text) {
        text = root.resolveQueryArg(text);
        var output = Engine.search(controller.backends || [], text || "", controller.stateForSearch(), controller.searchOptions());
        return root.debugVisualOutput(text, output);
    }

    function debugApplyQuery(text) {
        text = root.resolveQueryArg(text);
        controller.query = text || "";
        controller.generation += 1;
        if (!controller.query || controller.query.trim().length === 0) {
            controller.resultsClearRequested();
            return { query: controller.query, rows: [], timings: {} };
        }
        var output = Engine.search(controller.backends || [], controller.query, controller.stateForSearch(), controller.searchOptions());
        controller.lastQuery = output.query;
        controller.lastDirective = output.directive;
        controller.lastEvaluatedRoot = output.evaluatedRoot;
        controller.setResults((output.rows || []).slice(0, controller.maxResults), controller.query);
        return root.debugVisualOutput(controller.query, output);
    }

    function debugVisualOutput(text, output) {
        var rows = output && output.rows ? output.rows.slice(0, controller.maxResults) : [];
        return {
            query: output && output.query ? output.query.raw : text,
            timings: output ? output.timings || {} : {},
            rows: rows.map(function(row, index) {
                return {
                    key: controller.rowKey(row),
                    rank: index,
                    zValue: 10000 - index,
                    title: row ? row.title || "" : "",
                    source: row ? row.source || row.backendId || "" : "",
                    placement: row ? row.placement || "" : "",
                    children: row && row.children ? row.children.length : 0
                };
            })
        };
    }

    function queryPipeline(text) {
        text = root.resolveQueryArg(text);
        var output = Engine.search(controller.backends || [], text || "", controller.stateForSearch(),
            Object.assign(controller.searchOptions(), { showHidden: true, trace: true }));
        var diag = PolicyDiagnostics.empty();
        var rows = output.rows ? output.rows.slice(0, controller.maxResults) : [];
        var serializedRows = root.serializeRowsForQuery(rows, output.query);

        var backendEntries = (controller.backends || []).filter(function(b) { return !!b; }).map(function(b) {
            var routes = [];
            if (typeof b.routes !== "undefined")
                routes = b.routes || [];
            var helpPrefixes = [];
            if (typeof b.helpPrefixes !== "undefined")
                helpPrefixes = b.helpPrefixes || [];
            return {
                id: b.backendId || "",
                name: b.name || "",
                description: b.helpDescription || "",
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
            version: 3, type: "pipeline",
            query: output.query ? output.query.raw : text,
            directive: output.directive ? { active: output.directive.active, prefix: output.directive.prefix || "", label: output.directive.label || "", backendIds: output.directive.backendIds || [] } : { active: false },
            timings: output.timings || {},
            phases: output.phases || [],
            rows: serializedRows,
            totalResults: rows.length,
            backends: {
                total: backendEntries.length,
                entries: backendEntries,
                routingTree: { endpointCount: (controller.routingTree || {}).endpoints ? controller.routingTree.endpoints.length : 0 }
            },
            state: {
                selectedIndex: controller.selectedIndex,
                resultCount: controller.results.length,
                loading: controller.loading
            },
            diagnostics: PolicyDiagnostics.toDebug(diag)
        });
    }

    function queryPolicies(text) {
        text = root.resolveQueryArg(text);
        var output = Engine.search(controller.backends || [], text || "", controller.stateForSearch(),
            Object.assign(controller.searchOptions(), { showHidden: true }));
        var activeBackendIds = (controller.backends || []).filter(function(b) { return b && b.enabled; }).map(function(b) { return b.backendId || ""; });
        var policyInfo = root.collectActivePolicies(output.evaluatedRoot);
        return JSON.stringify({
            version: 2, type: "policies",
            query: text || "",
            activeBackends: activeBackendIds,
            policiesByKind: policyInfo.policiesByKind,
            diagnostics: policyInfo.diagnostics
        });
    }

    function collectActivePolicies(ev) {
        if (!ev) return { policiesByKind: {}, diagnostics: { warnings: [], errors: [], unresolved: [], legacyCount: 0, tupleCount: 0, objectCount: 0 } };
        var kinds = {};
        var legacyCount = 0, tupleCount = 0, objectCount = 0;
        function visit(evaluated) {
            var rawNode = evaluated.node || evaluated;
            var profile = (rawNode.evaluationProfile || {}).profile || {};
            for (var key in profile) {
                if (!kinds[key]) kinds[key] = {};
                var specs = profile[key];
                if (Array.isArray(specs)) {
                    for (var si = 0; si < specs.length; si += 1) {
                        var spec = PolicySpec.normalize(specs[si]);
                        var specKey = spec.name;
                        if (!kinds[key][specKey]) {
                            kinds[key][specKey] = { name: spec.name, baseName: spec.baseName, kind: spec.kind, args: spec.args, priority: spec.priority, source: spec.source, count: 0 };
                        }
                        kinds[key][specKey].count += 1;
                        var rawSpec = specs[si];
                        if (typeof rawSpec === "string") legacyCount += 1;
                        else if (Array.isArray(rawSpec)) tupleCount += 1;
                        else objectCount += 1;
                    }
                }
            }
            var children = evaluated.children || rawNode.children || [];
            for (var i = 0; i < children.length; i += 1)
                visit(children[i]);
        }
        visit(ev);
        var out = {};
        for (var kind in kinds) {
            out[kind] = [];
            for (var specKey in kinds[kind])
                out[kind].push(kinds[kind][specKey]);
        }
        return {
            policiesByKind: out,
            diagnostics: {
                warnings: [], errors: [], unresolved: [],
                legacyCount: legacyCount, tupleCount: tupleCount, objectCount: objectCount
            }
        };
    }

    function queryCases() {
        return JSON.stringify({
            version: 1, type: "cases",
            cases: root.regressionCaseQueries()
        });
    }

    function queryRunCases() {
        var cases = root.regressionCaseQueries();
        var results = [];
        for (var i = 0; i < cases.length; i += 1) {
            var q = cases[i];
            var output = Engine.search(controller.backends || [], q, controller.stateForSearch(),
                Object.assign(controller.searchOptions(), { trace: true }));
            var rows = output.rows || [];
            var visibleRows = rows.filter(function(r) { return r.ownVisible; });
            var top = visibleRows.length > 0 ? visibleRows[0] : null;
            var topBreadcrumb = "";
            if (top && top.breadcrumbs) {
                if (Array.isArray(top.breadcrumbs))
                    topBreadcrumb = top.breadcrumbs.join(" > ");
                else if (top.breadcrumbText)
                    topBreadcrumb = top.breadcrumbText;
            }
            results.push({
                query: q,
                totalRows: rows.length,
                visibleRows: visibleRows.length,
                topTitle: top ? top.title : null,
                topScore: top ? top.score : 0,
                topOwnScore: top ? top.ownScore : 0,
                topPlacement: top ? top.placement : null,
                topSource: top ? (top.source || top.backendId || "") : null,
                topExecutable: top ? !!top.executable : false,
                topBreadcrumbText: topBreadcrumb,
                timings: output.timings || {}
            });
        }
        return JSON.stringify({
            version: 1, type: "runCases",
            total: cases.length,
            results: results,
            summary: root.summarizeCaseResults(results)
        });
    }

    function regressionCaseQueries() {
        return [
            "?", "? ", "?au",
            "zen", "zen ", "zen priv", "zen win", "zen browser", "zen new",
            "wifi", "wifi ", "wifi on", "wifi off", "wifi toggle", "toggle wifi",
            "wo", "wt",
            ":", ":wifi", ":wifi ", ":wifi on", ":db wifi",
            "@apps", "@apps zen", "@web nix",
            "web nix", "web !gh nix",
            "db wifi", "dashboard wifi",
            "au", "aud", "audi", "audio",
            "en", "screen", "session",
            "newxos", "vpn ", "vpn of",
            "notes", "/tmp"
        ];
    }

    function summarizeCaseResults(results) {
        var totalMs = 0;
        var count = Math.max(1, results.length);
        for (var i = 0; i < results.length; i += 1)
            totalMs += results[i].timings.totalMs || 0;
        return {
            avgMs: totalMs / count,
            totalCases: results.length,
            maxRows: results.reduce(function(m, r) { return Math.max(m, r.totalRows); }, 0)
        };
    }
}
