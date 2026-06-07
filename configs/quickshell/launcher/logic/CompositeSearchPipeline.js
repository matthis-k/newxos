.pragma library
.import "CompositeSearchText.js" as Text
.import "CompositeSearchIndex.js" as Index
.import "CompositeSearchEvaluate.js" as Evaluate
.import "CompositeSearchFlatten.js" as Flatten
.import "CompositeSearchRows.js" as Rows
.import "CompositeSearchPolicies.js" as Policies


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
    var directive = parseDirective(rawQuery, backends);
    var query = tokenize(directive.searchRaw);
    var ctx = Object.assign({ query: query, directive: directive, visibilityThreshold: 0.18, showHidden: false, includePath: true }, options || {});
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
    return { rows: rows, query: query, directive: directive, evaluatedRoot: evaluated, timings: timings };
}

function suppressFallbackRows(rows, ctx) {
    if (!rows || !rows.length || ctx.directive.active)
        return rows;

    var hasNonFallback = rows.some(function(row) { return row.source !== "web"; });
    if (!hasNonFallback)
        return rows;

    return rows.filter(function(row) { return row.source !== "web"; });
}
