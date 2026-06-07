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

function search(backends, rawQuery, state, options) {
    var totalStart = nowMs();

    var routingTree = options && options.routingTree;
    var route = null;
    if (routingTree) {
        route = RoutingTree.routeQuery(routingTree, rawQuery);
    }
    var directive = route
        ? buildDirectiveFromRoute(rawQuery, route, backends)
        : parseDirective(rawQuery, backends);
    var query = tokenize(directive.searchRaw);
    var ctx = Object.assign({ query: query, directive: directive, routingTree: routingTree, route: route, visibilityThreshold: 0.18, showHidden: false, includePath: true }, options || {});

    var active = (backends || []).filter(function(b) {
        if (!b || !b.enabled)
            return false;
        if (typeof b.shouldParticipate === "function" && !b.shouldParticipate(rawQuery, directive, query))
            return false;
        return !directive.active || directive.backendIds.indexOf(b.backendId) >= 0;
    }).sort(function(a, b) { return (b.priority || 0) - (a.priority || 0); });
    var children = [];
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
    var rootNodeMs = nowMs() - rootNodeStart;
    var root = makeNode({ id: "root", kind: "root", label: "Root", children: children, evaluationProfile: { strategies: [] } });

    var candidateStart = nowMs();
    ctx.candidateIds = collectCandidateIdsForRoots(children, query, ctx.candidateCap || 256);
    var candidateMs = nowMs() - candidateStart;
    var candidateCount = countKeys(ctx.candidateIds);
    backendTimings["candidates"] = candidateCount;

    var evaluateStart = nowMs();
    var evaluated = evaluateNode(root, query, ctx);
    var evaluateMs = nowMs() - evaluateStart;

    var pathStart = nowMs();
    if (ctx.includePath && !query.isEmpty)
        applyInheritPolicies(evaluated, query, ctx);
    var pathMs = nowMs() - pathStart;

    var flattenStart = nowMs();
    var rows = finalizeRows(suppressFallbackRows(flattenForUi(evaluated, state, ctx), ctx), query, directive, ctx);
    var flattenMs = nowMs() - flattenStart;
    var timings = null;
    if (ctx.trace) {
        timings = {
            totalMs: nowMs() - totalStart,
            rootNodeMs: rootNodeMs,
            candidateMs: candidateMs,
            evaluateMs: evaluateMs,
            pathMs: pathMs,
            flattenMs: flattenMs,
            activeBackends: active.length,
            backendRoots: children.length,
            candidateIds: candidateCount,
            backends: backendTimings,
            rows: rows.length
        };
    }
    return { rows: rows, query: query, directive: directive, route: route, evaluatedRoot: evaluated, timings: timings };
}

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
        searchRaw: route.strippedQuery || rawQuery,
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
