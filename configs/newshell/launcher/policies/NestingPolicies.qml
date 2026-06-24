import QtQml
import "../" as Launcher
import "../logic/"

QtObject {
    Component.onCompleted: {
        Launcher.PolicyRegistry.registerNesting("self-item", function(ev, ctx, args) {
            return {
                intent: "self-item",
                includeChildren: "none",
                childSource: "evaluated-children",
                retainContext: false,
                allowVisualTakeover: true,
                reason: "self-item: standalone leaf result"
            };
        });

        Launcher.PolicyRegistry.registerNesting("self-group-on-trailing-space", function(ev, ctx, args) {
            var ownMatched = !!(ev && (ev.ownVisible || (ev.ownScore || 0) > 0));
            var trailing = !!(ctx && ctx.query && ctx.query.lastTokenEmpty);
            var residual = (ev && ev.tokenFlow && ev.tokenFlow.passed) ? ev.tokenFlow.passed.length : 0;
            var isBrowse = ownMatched && trailing && residual === 0;
            return {
                intent: isBrowse ? "self-group" : "self-item",
                includeChildren: isBrowse ? "all" : "none",
                childSource: "evaluated-children",
                retainContext: isBrowse,
                allowVisualTakeover: false,
                reason: isBrowse
                    ? "self-group-on-trailing-space: trailing browse includes all children"
                    : "self-group-on-trailing-space: not a trailing browse"
            };
        });

        Launcher.PolicyRegistry.registerNesting("self-group-with-matching-children", function(ev, ctx, args) {
            var ownMatched = !!(ev && (ev.ownVisible || (ev.ownScore || 0) > 0));
            var trailing = !!(ctx && ctx.query && ctx.query.lastTokenEmpty);
            var residual = (ev && ev.tokenFlow && ev.tokenFlow.passed) ? ev.tokenFlow.passed.length : 0;
            var hasResidualSearch = ownMatched && !trailing && residual > 0;
            return {
                intent: hasResidualSearch ? "self-group" : "parent-item",
                includeChildren: hasResidualSearch ? "matching" : "none",
                childSource: "evaluated-children",
                retainContext: true,
                allowVisualTakeover: false,
                reason: hasResidualSearch
                    ? "self-group-with-matching-children: " + residual + " residual tokens filter children"
                    : "self-group-with-matching-children: no residual tokens"
            };
        });

        Launcher.PolicyRegistry.registerNesting("namespace-dynamic-group", function(ev, ctx, args) {
            var ownMatched = !!(ev && (ev.ownVisible || (ev.ownScore || 0) > 0));
            var trailing = !!(ctx && ctx.query && ctx.query.lastTokenEmpty);
            var residual = (ev && ev.tokenFlow && ev.tokenFlow.passed) ? ev.tokenFlow.passed.length : 0;
            var isBrowse = trailing && residual === 0;
            var hasResidualSearch = !trailing && residual > 0;
            var include;
            if (isBrowse) include = "all";
            else if (hasResidualSearch) include = "matching";
            else include = "none";
            var isGroup = ownMatched && (isBrowse || hasResidualSearch);
            var childInfo = ev && ev.children ? "kids=" + ev.children.length + " vis=" + ev.children.filter(function(c) { return c.visible; }).length + " cand=" + ev.children.filter(function(c) { return c.candidate; }).length : "no-ev-children";
            return {
                intent: isGroup ? "self-group" : "parent-item",
                includeChildren: include,
                childSource: "evaluated-children",
                retainContext: true,
                allowVisualTakeover: false,
                reason: isGroup
                    ? (isBrowse ? "namespace-dynamic-group: trailing browse " + include + " children (" + childInfo + ")"
                       : "namespace-dynamic-group: matching children filtered by residual (" + childInfo + ")")
                    : "namespace-dynamic-group: own match without browse (" + childInfo + ")"
            };
        });

        Launcher.PolicyRegistry.registerNesting("desktop-app-actions", function(ev, ctx, args) {
            var ownMatched = !!(ev && (ev.ownVisible || (ev.ownScore || 0) > 0));
            var trailing = !!(ctx && ctx.query && ctx.query.lastTokenEmpty);
            var residual = (ev && ev.tokenFlow && ev.tokenFlow.passed) ? ev.tokenFlow.passed.length : 0;
            var isBrowse = trailing && residual === 0;
            var hasResidualSearch = !trailing && residual > 0;
            var include;
            if (isBrowse) include = "all";
            else if (hasResidualSearch) include = "matching";
            else include = "none";
            var isGroup = ownMatched && (isBrowse || hasResidualSearch);
            return {
                intent: isGroup ? "self-group" : "self-item",
                includeChildren: include,
                childSource: "evaluated-children",
                retainContext: isGroup,
                allowVisualTakeover: hasResidualSearch,
                reason: isGroup
                    ? (isBrowse ? "desktop-app-actions: trailing browse " + include + " children"
                       : "desktop-app-actions: matching children for '" + (ctx.query ? ctx.query.raw : "") + "'")
                    : "desktop-app-actions: own match without browse"
            };
        });
    }
}
