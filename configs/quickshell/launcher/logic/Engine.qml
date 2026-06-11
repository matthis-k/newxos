pragma Singleton
import QtQml
import Quickshell
import "Tokenize.qml"
import "IndexBuilder.qml"
import "Evaluate.qml"
import "ResultShaping.qml"
import "RenderedRows.qml"
import "Rows.qml"
import "RoutingTree.js" as JsRoutingTree

Singleton {
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

    function buildRowsFromShaped(shapedResult, state, ctx) {
        var maxTreeDepth = shapedResult.maxTreeDepth;

        function buildChildTree(ev, currentDepth, maxDepth, includeAllChildren) {
            if (maxDepth <= 0 || !ev.children) return [];
            var filtered = ev.children.filter(function(c) {
                return c.allowed && c.node.kind !== "backend" && (includeAllChildren || c.visible || c.score >= 0.25);
            });
            return buildChildRows(filtered, currentDepth, maxDepth, includeAllChildren);
        }

        function buildChildRows(children, currentDepth, maxDepth, includeAllChildren) {
            if (maxDepth <= 0 || !children) return [];
            var filtered = children.filter(function(c) {
                return c.allowed && c.node.kind !== "backend" && (includeAllChildren || c.visible || c.score >= 0.25);
            });
            return filtered.map(function(child) {
                var grandChildren = buildChildTree(child, currentDepth + 1, maxDepth - 1, includeAllChildren);
                return RenderedRows.toResultRow(child, currentDepth + 1, state, ctx, grandChildren);
            });
        }

        return shapedResult.shaped.map(function(item) {
            var includeAllChildren = item.options && item.options.includeAllChildren;
            var childRows;
            if (item.childEvs != null) {
                if (item.childEvs.length > 0)
                    childRows = buildChildRows(item.childEvs, item.depth, maxTreeDepth, includeAllChildren);
            } else {
                childRows = buildChildTree(item.ev, item.depth, maxTreeDepth, false);
            }
            if (!childRows) childRows = [];
            return RenderedRows.toResultRow(item.ev, item.depth, state, ctx, childRows, item.options);
        });
    }

    function search(backends, rawQuery, state, options) {
        var opts = Object.assign({}, options || {}, { sync: true });
        return searchAsync(backends, rawQuery, state, opts, function() { return true; }, null);
    }

    function searchAsync(backends, rawQuery, state, options, isCurrent, onComplete) {
        var sync = options && options.sync;
        var schedule = sync ? function(fn) { fn(); } : Qt.callLater;
        var totalStart = Tokenize.nowMs();
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
                route = JsRoutingTree.routeQuery(routingTree, rawQuery);
            directive = route
                ? buildDirectiveFromRoute(rawQuery, route, backends)
                : Tokenize.parseDirective(rawQuery, backends);
            query = Tokenize.tokenize(directive.searchRaw);
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
            var rootNodeStart = Tokenize.nowMs();
            for (var i = 0; i < active.length; i += 1) {
                var backend = active[i];
                var bStart = Tokenize.nowMs();
                var node = backend.rootNode ? backend.rootNode(query, ctx) : null;
                var bMs = Tokenize.nowMs() - bStart;
                if (node) {
                    node.backendId = node.backendId || backend.backendId;
                    node.backendPriority = backend.priority || 0;
                    children.push(Tokenize.makeNode(node));
                }
                backendTimings["root:" + (backend.backendId || i)] = bMs;
            }
            ctx.backendTimings = backendTimings;
            ctx.rootNodeMs = Tokenize.nowMs() - rootNodeStart;
            root = Tokenize.makeNode({ id: "root", kind: "root", label: "Root", children: children, evaluationProfile: { strategies: [] } });

            schedule(phase2);
        }

        function phase2() {
            if (!isCurrent()) { abort(); return; }

            var candidateStart = Tokenize.nowMs();
            ctx.candidateIds = IndexBuilder.collectCandidateIdsForRoots(children, query, ctx.candidateCap || 256);
            ctx.candidateMs = Tokenize.nowMs() - candidateStart;
            ctx.candidateCount = Tokenize.countKeys(ctx.candidateIds);

            schedule(phase3);
        }

        function phase3() {
            if (!isCurrent()) { abort(); return; }

            var evaluateStart = Tokenize.nowMs();
            var evaluated = Evaluate.evaluateNode(root, query, ctx);
            ctx.evaluateMs = Tokenize.nowMs() - evaluateStart;
            ctx.evaluated = evaluated;

            schedule(phase4);
        }

        function phase4() {
            if (!isCurrent()) { abort(); return; }

            var pathStart = Tokenize.nowMs();
            if (ctx.includePath && !query.isEmpty)
                Evaluate.applyInheritPolicies(ctx.evaluated, query, ctx);
            ctx.pathMs = Tokenize.nowMs() - pathStart;

            schedule(phase5);
        }

        function phase5() {
            if (!isCurrent()) { abort(); return; }

            var shapeStart = Tokenize.nowMs();
            var shapedResult = ResultShaping.shape(ctx.evaluated, state, ctx);
            var rows = buildRowsFromShaped(shapedResult, state, ctx);
            rows = suppressFallbackRows(rows, ctx);
            rows = Rows.finalizeRows(rows, query, directive, ctx);
            var shapeMs = Tokenize.nowMs() - shapeStart;

            if (ctx.trace) {
                timings = {
                    totalMs: Tokenize.nowMs() - totalStart, rootNodeMs: ctx.rootNodeMs, candidateMs: ctx.candidateMs,
                    evaluateMs: ctx.evaluateMs, pathMs: ctx.pathMs, shapeMs: shapeMs,
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
}
