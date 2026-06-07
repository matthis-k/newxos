.pragma library
.import "CompositeSearchText.js" as Text
.import "CompositeSearchIndex.js" as Index
.import "CompositeSearchEvaluate.js" as Evaluate
.import "CompositeSearchFlatten.js" as Flatten
.import "CompositeSearchRows.js" as Rows
.import "CompositeSearchPolicies.js" as Policies
.import "RoutingTree.js" as RoutingTree

var nowMs = Text.nowMs;
var parseDirective = Text.parseDirective;
var tokenize = Text.tokenize;
var makeNode = Text.makeNode;
var countKeys = Text.countKeys;
var buildSearchIndex = Index.buildSearchIndex;
var collectCandidateIdsForRoots = Index.collectCandidateIdsForRoots;
var evaluateNode = Evaluate.evaluateNode;
var applyInheritPolicies = Evaluate.applyInheritPolicies;
var flattenForUi = Flatten.flattenForUi;
var finalizeRows = Rows.finalizeRows;

function buildDirectiveFromRoute(rawQuery, route, backends) {
    if (!route || !route.endpoints || route.endpoints.length === 0)
        return { active: false, raw: rawQuery, searchRaw: rawQuery, prefix: "", label: "All", tags: [], kinds: [], backendIds: [] };

    var backendIds = [];
    var seen = {};
    for (var i = 0; i < route.endpoints.length; i += 1) {
        var ep = route.endpoints[i];
        var id = String(ep.node && ep.node.backendId || "");
        if (id && !seen[id]) {
            seen[id] = true;
            backendIds.push(id);
        }
    }

    var prefix = route.endpoints[0] ? (route.endpoints[0].prefix || "") : "";
    var label = backendIds.length === 1 ? findHelpTitle(backends, backendIds[0]) : (backendIds.length > 1 ? "Multiple" : "All");

    return {
        active: route.combine === "exclusive" || (backendIds.length > 0 && prefix !== ""),
        raw: rawQuery,
        searchRaw: route.strippedQuery !== undefined && route.strippedQuery !== null ? route.strippedQuery : rawQuery,
        prefix: prefix,
        label: label,
        tags: [],
        kinds: [],
        backendIds: backendIds
    };
}

function findHelpTitle(backends, backendId) {
    for (var i = 0; i < (backends || []).length; i += 1) {
        var b = backends[i];
        if (b && b.backendId === backendId)
            return b.helpTitle || b.name || b.backendId;
    }
    return backendId;
}

function suppressFallbackRows(rows, ctx) {
    if (!rows || !rows.length || ctx.directive.active)
        return rows;

    var hasNonFallback = rows.some(function(row) { return row.source !== "web"; });
    if (!hasNonFallback)
        return rows;

    return rows.filter(function(row) { return row.source !== "web"; });
}

function searchAsync(backends, rawQuery, state, options, isCurrent, onComplete) {
    var sync = options && options.sync;
    var schedule = sync ? function(fn) { fn(); } : Qt.callLater;
    var totalStart = nowMs();
    var routingTree = options && options.routingTree;
    var ctx = Object.assign({ query: null, directive: null, routingTree: routingTree, route: null, visibilityThreshold: 0.18, showHidden: false, includePath: true }, options || {});

    var active = null;
    var children = null;
    var root = null;
    var route = null;
    var directive = null;
    var query = null;
    var timings = null;
    var syncResult = null;

    function abort() {
        if (onComplete) onComplete(null);
    }

    function phase0() {
        if (!isCurrent()) { abort(); return; }

        if (routingTree)
            route = RoutingTree.routeQuery(routingTree, rawQuery);
        directive = route
            ? buildDirectiveFromRoute(rawQuery, route, backends)
            : parseDirective(rawQuery, backends);
        query = tokenize(directive.searchRaw);
        ctx.query = query;
        ctx.directive = directive;
        ctx.route = route;

        active = (backends || []).filter(function(b) {
            if (!b || !b.enabled) return false;
            if (typeof b.shouldParticipate === "function" && !b.shouldParticipate(rawQuery, directive, query)) return false;
            return !directive.active || directive.backendIds.indexOf(b.backendId) >= 0;
        }).sort(function(a, b) { return (b.priority || 0) - (a.priority || 0); });

        schedule(phase1);
    }

    function phase1() {
        if (!isCurrent()) { abort(); return; }

        children = [];
        var backendTimings = {};
        var rootNodeStart = nowMs();
        for (var i = 0; i < active.length; i += 1) {
            var backend = active[i];
            var bStart = nowMs();
            var node = backend.rootNode ? backend.rootNode(query, ctx) : null;
            var bMs = nowMs() - bStart;
            if (node) {
                node.backendId = node.backendId || backend.backendId;
                node.backendPriority = backend.priority || 0;
                children.push(makeNode(node));
            }
            backendTimings["root:" + (backend.backendId || i)] = bMs;
        }
        ctx.backendTimings = backendTimings;
        ctx.rootNodeMs = nowMs() - rootNodeStart;
        root = makeNode({ id: "root", kind: "root", label: "Root", children: children, evaluationProfile: { strategies: [] } });

        schedule(phase2);
    }

    function phase2() {
        if (!isCurrent()) { abort(); return; }

        var candidateStart = nowMs();
        ctx.candidateIds = collectCandidateIdsForRoots(children, query, ctx.candidateCap || 256);
        ctx.candidateMs = nowMs() - candidateStart;
        ctx.candidateCount = countKeys(ctx.candidateIds);

        schedule(phase3);
    }

    function phase3() {
        if (!isCurrent()) { abort(); return; }

        var evaluateStart = nowMs();
        var evaluated = evaluateNode(root, query, ctx);
        ctx.evaluateMs = nowMs() - evaluateStart;
        ctx.evaluated = evaluated;

        schedule(phase4);
    }

    function phase4() {
        if (!isCurrent()) { abort(); return; }

        var pathStart = nowMs();
        if (ctx.includePath && !query.isEmpty)
            applyInheritPolicies(ctx.evaluated, query, ctx);
        ctx.pathMs = nowMs() - pathStart;

        schedule(phase5);
    }

    function phase5() {
        if (!isCurrent()) { abort(); return; }

        var flattenStart = nowMs();
        var rows = finalizeRows(suppressFallbackRows(flattenForUi(ctx.evaluated, state, ctx), ctx), query, directive, ctx);
        var flattenMs = nowMs() - flattenStart;

        if (ctx.trace) {
            timings = {
                totalMs: nowMs() - totalStart, rootNodeMs: ctx.rootNodeMs, candidateMs: ctx.candidateMs,
                evaluateMs: ctx.evaluateMs, pathMs: ctx.pathMs, flattenMs: flattenMs,
                activeBackends: active.length, backendRoots: children.length, candidateIds: ctx.candidateCount,
                backends: ctx.backendTimings, rows: rows.length
            };
        }

        var result = { rows: rows, query: query, directive: directive, route: route, evaluatedRoot: ctx.evaluated, timings: timings };
        syncResult = result;
        if (onComplete) onComplete(result);
    }

    schedule(phase0);
    return syncResult;
}
