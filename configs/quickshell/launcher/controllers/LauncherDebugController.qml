import QtQuick
import QtQml
import "../logic/"

Item {
    id: root

    property var controller: null

    function copyJsonValue(value, depth) {
        depth = depth === undefined ? 0 : depth;
        if (depth > 6 || value === undefined || typeof value === "function")
            return null;
        if (value === null || typeof value === "string" || typeof value === "number" || typeof value === "boolean")
            return value;
        if (Array.isArray(value))
            return value.map(function(item) { return root.copyJsonValue(item, depth + 1); });
        if (typeof value === "object") {
            var out = {};
            for (var key in value) {
                if (key === "raw" || key === "parent" || key === "execute")
                    continue;
                var copied = root.copyJsonValue(value[key], depth + 1);
                if (copied !== null)
                    out[key] = copied;
            }
            return out;
        }
        return null;
    }

    function jsonPreview(value) {
        if (value === undefined)
            return "undefined";
        if (value === null)
            return "null";
        if (typeof value === "string")
            return value.slice(0, 80);
        if (typeof value === "number" || typeof value === "boolean")
            return String(value);
        if (Array.isArray(value))
            return "array(" + value.length + ")";
        if (typeof value === "function")
            return "function";
        if (typeof value === "object")
            return Object.keys(value).slice(0, 8).join(",");
        return typeof value;
    }

    function findInvalidJsonValue(value, path, seen, seenPaths) {
        if (value === undefined)
            return { path: path, reason: "undefined", preview: root.jsonPreview(value) };
        if (typeof value === "function")
            return { path: path, reason: "function", preview: root.jsonPreview(value) };
        if (typeof value === "number" && !isFinite(value))
            return { path: path, reason: "non-finite number", preview: root.jsonPreview(value) };
        if (value === null || typeof value === "string" || typeof value === "number" || typeof value === "boolean")
            return null;
        if (typeof value !== "object")
            return { path: path, reason: typeof value, preview: root.jsonPreview(value) };

        var seenIndex = seen.indexOf(value);
        if (seenIndex >= 0)
            return { path: path, reason: "cycle", preview: "first seen at " + seenPaths[seenIndex] };
        seen.push(value);
        seenPaths.push(path);

        if (Array.isArray(value)) {
            for (var ai = 0; ai < value.length; ai += 1) {
                var arrInvalid = root.findInvalidJsonValue(value[ai], path + "[" + ai + "]", seen, seenPaths);
                if (arrInvalid)
                    return arrInvalid;
            }
        } else {
            for (var key in value) {
                var childValue = value[key];
                if ((key === "raw" || key === "parent" || key === "execute") && childValue && typeof childValue === "object")
                    return { path: path + "." + key, reason: "forbidden reference key", preview: root.jsonPreview(value[key]) };
                if (key === "execute" && typeof childValue === "function")
                    return { path: path + "." + key, reason: "forbidden executable function", preview: root.jsonPreview(value[key]) };
                var invalid = root.findInvalidJsonValue(childValue, path + "." + key, seen, seenPaths);
                if (invalid)
                    return invalid;
            }
        }

        seen.pop();
        seenPaths.pop();
        return null;
    }

    function logJsonValidation(label, value) {
        var invalid = root.findInvalidJsonValue(value, "$", [], []);
        if (invalid) {
            console.warn("[LAUNCHER PIPELINE DTO INVALID] " + label + " path=" + invalid.path + " reason=" + invalid.reason + " preview=" + invalid.preview);
            return false;
        }
        return true;
    }

    function serializeRow(row, depth, options) {
        depth = depth === undefined ? 0 : depth;
        options = options || {};
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
            risk: root.copyJsonValue(row.risk),
            selectable: controller.isSelectable(row),
            breadcrumbs: row.breadcrumbs || [],
            breadcrumbText: row.breadcrumbText || "",
            filterable: !!row.filterable,
            lazy: !!row.lazy,
            alwaysExpanded: row.alwaysExpanded !== false,
            expandable: !!(row.children && row.children.length > 0) || !!row.lazy,
            switchState: row.switchState === undefined ? null : row.switchState,
            control: root.copyJsonValue(row.control),
            presentation: root.copyJsonValue(row.presentation),
            defaultAction: root.copyJsonValue(row.defaultAction),
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
        if (row.children && row.children.length) {
            var maxChildren = options.maxChildren === undefined ? row.children.length : Math.max(0, Number(options.maxChildren));
            var childSource = row.children.slice(0, maxChildren);
            out.children = childSource.map(function(child) { return root.serializeRow(child, depth + 1, options); }).filter(Boolean);
            if (row.children.length > childSource.length) {
                out.childrenTruncated = true;
                out.childCount = row.children.length;
            }
        }
        if (depth > 0) {
            out.evidence = [];
            out.scoreBundle = null;
        }
        if (row.switchActions) {
            out.switchActions = {};
            for (var k in row.switchActions)
                out.switchActions[k] = { id: row.switchActions[k].id, label: row.switchActions[k].label };
        }
        if (depth === 0 && row.recipes) {
            out.recipes = {};
            for (var rk in row.recipes) {
                if (Array.isArray(row.recipes[rk]))
                    out.recipes[rk] = root.copyJsonValue(row.recipes[rk]);
            }
        }
        if (depth === 0 && row.interactions) {
            out.interactions = {};
            for (var ik in row.interactions) {
                var entry = row.interactions[ik];
                if (entry && typeof entry === "object")
                    out.interactions[ik] = { label: entry.label || "", recipe: root.copyJsonValue(entry.recipe || []) };
            }
        }
        return out;
    }

    function serializeRowsForQuery(rows, queryInfo, options) {
        var previousLastQuery = controller.lastQuery;
        controller.lastQuery = queryInfo || null;
        var out = (rows || []).map(function(row) { return root.serializeRow(row, 0, options || {}); }).filter(Boolean);
        controller.lastQuery = previousLastQuery;
        return out;
    }

    function serializeRowOverview(row, index) {
        if (!row) return null;
        var children = row.children || [];
        var actions = row.actions || [];
        return {
            rank: index,
            id: row.id || "",
            nodeId: row.nodeId || "",
            title: row.title || "",
            subtitle: row.subtitle || "",
            source: row.source || row.backendId || "",
            kind: row.kind || "",
            score: row.score || 0,
            ownScore: row.ownScore || 0,
            inheritedScore: row.inheritedScore || 0,
            descendantScore: row.descendantScore || 0,
            ownVisible: !!row.ownVisible,
            placement: row.placement || "",
            executable: !!row.executable,
            filterable: !!row.filterable,
            lazy: !!row.lazy,
            expandable: children.length > 0 || !!row.lazy,
            childCount: children.length,
            childPreview: children.slice(0, 8).map(function(child) { return { title: child.title || "", nodeId: child.nodeId || child.id || "" }; }),
            actionCount: actions.length,
            defaultAction: row.defaultAction ? { id: row.defaultAction.id || "", label: row.defaultAction.label || "" } : null,
            switchState: row.switchState === undefined ? null : row.switchState,
            control: row.control ? { kind: row.control.kind || "", value: row.control.value === undefined ? null : row.control.value } : null,
            breadcrumbs: row.breadcrumbs || [],
            breadcrumbText: row.breadcrumbText || ""
        };
    }

    function serializeRowsOverview(rows) {
        return (rows || []).map(function(row, index) { return root.serializeRowOverview(row, index); }).filter(Boolean);
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

    function parsePipelineConfig(arg) {
        var config = { query: root.resolveQueryArg(arg), focusNodeId: "", showHidden: controller.showHidden, details: [], overview: true, maxChildren: 32 };
        if (!arg)
            return config;
        var trimmed = String(arg).trim();
        if (trimmed.length === 0 || (trimmed[0] !== "{" && trimmed[0] !== "["))
            return config;
        try {
            var parsed = JSON.parse(trimmed);
            if (!parsed || typeof parsed !== "object" || Array.isArray(parsed))
                return config;
            if (parsed.query !== undefined)
                config.query = String(parsed.query);
            config.focusNodeId = String(parsed.focusNodeId || parsed.nodeId || parsed.id || "");
            config.details = root.normalizePipelineDetails(parsed.details !== undefined ? parsed.details : (parsed.detail !== undefined ? parsed.detail : (parsed.sections !== undefined ? parsed.sections : parsed.include)));
            var mode = String(parsed.mode || parsed.view || "").toLowerCase();
            if (mode === "full" || mode === "debug")
                config.details = ["rows", "phases", "backends", "diagnostics"];
            else if (mode === "overview" || mode === "compact")
                config.details = [];
            config.overview = config.details.length === 0;
            if (parsed.showHidden !== undefined)
                config.showHidden = !!parsed.showHidden;
            else if (config.focusNodeId)
                config.showHidden = true;
            if (parsed.maxChildren !== undefined)
                config.maxChildren = Math.max(0, Math.min(256, Number(parsed.maxChildren)));
            else if (config.focusNodeId && root.pipelineWants(config, "rows"))
                config.maxChildren = 96;
        } catch (error) {}
        return config;
    }

    function normalizePipelineDetails(value) {
        if (value === undefined || value === null || value === false)
            return [];
        if (value === true || String(value).toLowerCase() === "all" || String(value).toLowerCase() === "full")
            return ["rows", "phases", "backends", "diagnostics"];
        var items = Array.isArray(value) ? value : String(value).split(/[,\s]+/);
        var out = [];
        for (var i = 0; i < items.length; i += 1) {
            var item = String(items[i] || "").toLowerCase().trim();
            if (!item) continue;
            if (item === "row") item = "rows";
            if (item === "phase") item = "phases";
            if (item === "backend") item = "backends";
            if (item === "diagnostic") item = "diagnostics";
            if (["rows", "phases", "backends", "diagnostics"].indexOf(item) >= 0 && out.indexOf(item) < 0)
                out.push(item);
        }
        return out;
    }

    function pipelineWants(config, detail) {
        return (config.details || []).indexOf(detail) >= 0;
    }

    function nodeIdMatchesFocus(nodeId, focusNodeId) {
        if (!focusNodeId)
            return true;
        nodeId = nodeId || "";
        return nodeId === focusNodeId || nodeId.indexOf(focusNodeId + ":") === 0;
    }

    function filterRowForFocus(row, focusNodeId) {
        if (!row)
            return null;
        if (root.nodeIdMatchesFocus(row.nodeId || row.id || "", focusNodeId))
            return row;
        var children = (row.children || []).map(function(child) { return root.filterRowForFocus(child, focusNodeId); }).filter(Boolean);
        if (children.length === 0)
            return null;
        return Object.assign({}, row, { children: children });
    }

    function filterRowsForFocus(rows, focusNodeId) {
        if (!focusNodeId)
            return rows || [];
        return (rows || []).map(function(row) { return root.filterRowForFocus(row, focusNodeId); }).filter(Boolean);
    }

    function filterPhasesForFocus(phases, focusNodeId) {
        if (!focusNodeId)
            return phases || [];
        var focusBackend = focusNodeId.split(":")[0] || "";
        return (phases || []).map(function(phase) {
            var out = Object.assign({}, phase);
            if (Array.isArray(out.roots) && focusBackend)
                out.roots = out.roots.filter(function(item) { return item.backendId === focusBackend; });
            if (Array.isArray(out.childScoreBundles) && focusBackend)
                out.childScoreBundles = out.childScoreBundles.filter(function(item) { return item.backendId === focusBackend; });
            if (Array.isArray(out.shaped))
                out.shaped = out.shaped.filter(function(item) { return root.nodeIdMatchesFocus(item.nodeId || "", focusNodeId); });
            return out;
        });
    }

    function summarizePhase(phase) {
        if (!phase) return null;
        var out = { phase: phase.phase, name: phase.name || "" };
        if (phase.searchRaw !== undefined) out.searchRaw = phase.searchRaw;
        if (phase.directive) out.directive = phase.directive;
        if (phase.tokens) out.tokens = phase.tokens;
        if (phase.activeBackendIds) out.activeBackendIds = phase.activeBackendIds;
        if (phase.rootNodeMs !== undefined) out.rootNodeMs = phase.rootNodeMs;
        if (phase.perBackendMs) out.perBackendMs = phase.perBackendMs;
        if (phase.roots) out.rootCount = phase.roots.length;
        if (phase.candidateMs !== undefined) out.candidateMs = phase.candidateMs;
        if (phase.candidateCount !== undefined) out.candidateCount = phase.candidateCount;
        if (phase.evaluateMs !== undefined) out.evaluateMs = phase.evaluateMs;
        if (phase.totalNodes !== undefined) out.totalNodes = phase.totalNodes;
        if (phase.visibleNodes !== undefined) out.visibleNodes = phase.visibleNodes;
        if (phase.childScoreBundles) out.childScoreBundleCount = phase.childScoreBundles.length;
        if (phase.pathMs !== undefined) out.pathMs = phase.pathMs;
        if (phase.shapeMs !== undefined) out.shapeMs = phase.shapeMs;
        if (phase.shapedCount !== undefined) out.shapedCount = phase.shapedCount;
        if (phase.placements) out.placements = phase.placements;
        if (phase.rows !== undefined) out.rows = phase.rows;
        if (phase.totalMs !== undefined) out.totalMs = phase.totalMs;
        return out;
    }

    function summarizePhases(phases) {
        return (phases || []).map(function(phase) { return root.summarizePhase(phase); }).filter(Boolean);
    }

    function queryPipeline(text) {
        var stage = "resolve";
        try {
            var pipelineConfig = root.parsePipelineConfig(text);
            text = pipelineConfig.query;
            stage = "search";
            var output = Engine.search(controller.backends || [], text || "", controller.stateForSearch(),
                Object.assign(controller.searchOptions(), { showHidden: pipelineConfig.showHidden, trace: true }));
            var diag = PolicyDiagnostics.empty();
            var allRows = output.rows || [];
            var rows = pipelineConfig.focusNodeId
                ? root.filterRowsForFocus(allRows, pipelineConfig.focusNodeId).slice(0, controller.maxResults)
                : allRows.slice(0, controller.maxResults);
            var detailedRows = root.pipelineWants(pipelineConfig, "rows");
            stage = detailedRows ? "serialize-rows" : "serialize-row-overview";
            var serializedRows = detailedRows
                ? root.serializeRowsForQuery(rows, output.query, { maxChildren: pipelineConfig.maxChildren })
                : root.serializeRowsOverview(rows);

            stage = "serialize-backends";
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

            var detailedPhases = root.pipelineWants(pipelineConfig, "phases");
            var detailedBackends = root.pipelineWants(pipelineConfig, "backends");
            var detailedDiagnostics = root.pipelineWants(pipelineConfig, "diagnostics");
            var payload = {
                version: 3, type: "pipeline",
                query: output.query ? output.query.raw : text,
                directive: output.directive ? { active: output.directive.active, prefix: output.directive.prefix || "", label: output.directive.label || "", backendIds: output.directive.backendIds || [] } : { active: false },
                timings: output.timings || {},
                phases: detailedPhases
                    ? root.filterPhasesForFocus(output.phases || [], pipelineConfig.focusNodeId)
                    : root.summarizePhases(root.filterPhasesForFocus(output.phases || [], pipelineConfig.focusNodeId)),
                rows: serializedRows,
                totalResults: rows.length,
                debug: {
                    focusNodeId: pipelineConfig.focusNodeId || null,
                    showHidden: !!pipelineConfig.showHidden,
                    unfilteredResults: allRows.length,
                    detailMode: pipelineConfig.overview ? "overview" : "custom",
                    details: pipelineConfig.details,
                    maxChildren: pipelineConfig.maxChildren,
                    availableDetails: ["rows", "phases", "backends", "diagnostics"]
                },
                backends: {
                    total: backendEntries.length,
                    entries: detailedBackends ? backendEntries : [],
                    enabledIds: backendEntries.filter(function(entry) { return entry.enabled; }).map(function(entry) { return entry.id; }),
                    routingTree: { endpointCount: (controller.routingTree || {}).endpoints ? controller.routingTree.endpoints.length : 0 }
                },
                state: {
                    selectedIndex: controller.selectedIndex,
                    resultCount: controller.results.length,
                    loading: controller.loading
                },
                diagnostics: detailedDiagnostics ? PolicyDiagnostics.toDebug(diag) : { omitted: true }
            };
            root.logJsonValidation("query=" + (text || "") + " rows=" + serializedRows.length, payload);
            stage = "stringify";
            var encoded = JSON.stringify(payload);
            if (encoded.length > 100000)
                console.warn("[LAUNCHER PIPELINE DTO OVERSIZE] query=" + (text || "") + " bytes=" + encoded.length + " focus=" + (pipelineConfig.focusNodeId || ""));
            return encoded;
        } catch (error) {
            console.warn("[LAUNCHER PIPELINE DTO ERROR] stage=" + stage + " query=" + (text || "") + " error=" + String(error));
            return JSON.stringify({ version: 3, type: "pipeline", query: text || "", error: String(error), stage: stage });
        }
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
            "v", "new", "zen", "zen ", "zen priv", "zen win", "zen browser", "zen new",
            "wifi", "wifi ", "wifi on", "wifi off", "wifi toggle", "toggle wifi",
            "wo", "wt",
            ":", ":wifi", ":wifi ", ":wifi on", ":db wifi",
            "@apps", "@apps zen", "@web nix",
            "web nix", "web !gh nix",
            "db wifi", "dashboard wifi",
            "au", "aud", "audi", "audio",
            "en", "screen", "session",
            "newxos", "vpn", "vpn ", "vpn ger", "vpn germany", "vpn of",
            "ger", "alg", "bel", "swe", "germany", "algeria", "belgium", "sweden",
            "net", "networking",
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
