import QtQml
import "../logic/QueryParsing.js" as QueryParsing
import "../logic/Router.js" as Router
import "../logic/ResultUtils.js" as ResultUtils

QtObject {
    id: root

    property string backendId: ""
    property string name: ""
    property string category: ""
    property string helpTitle: name
    property string helpDescription: ""
    property string helpIcon: "system-search"
    property var helpPrefixes: []
    property bool enabled: true
    property int priority: 0
    property int maxResults: 5
    property var routes: []

    function isEnabled(query) {
        if (!root.enabled)
            return false;
        if (!root.routes || root.routes.length === 0)
            return true;
        for (const route of root.routes) {
            if (Router.routeMatches(query, route))
                return true;
        }
        return false;
    }

    function results(query) {
        return [];
    }

    function activate(result, action) {
    }

    function queryText(query) {
        const parsed = QueryParsing.parse(query);
        for (const route of root.routes || []) {
            if (Router.routeMatches(query, route)) {
                const routed = Router.extractText(query, route);
                if (route.pattern)
                    return routed;
                if (parsed.explicit && parsed.targetBackend === root.backendId)
                    return parsed.text || "";
                return routed;
            }
        }
        return query || "";
    }

    function matchQuery(query) {
        const parsed = QueryParsing.parse(query);
        for (const route of root.routes || []) {
            if (Router.routeMatches(query, route)) {
                const routed = Router.extractText(query, route);
                if (route.pattern)
                    return { text: routed, route: route };
                if (parsed.explicit && parsed.targetBackend === root.backendId)
                    return { text: parsed.text || "", route: route };
                return { text: routed, route: route };
            }
        }
        return { text: query || "", route: null };
    }

    function buildResult(opts) {
        if (!opts || !opts.id || !opts.title)
            return null;

        const actions = (opts.actions || []).map((action, index) => {
            if (!action || !action.id || !action.label)
                return null;
            return {
                id: action.id,
                label: action.label,
                icon: action.icon || null,
                default: !!action.default || index === 0,
                intent: action.intent || null
            };
        }).filter(Boolean);

        if (actions.length === 0)
            return null;

        if (!actions.some(action => action.default))
            actions[0].default = true;

        const result = {
            id: opts.id,
            source: root.backendId,
            category: root.category || null,
            title: opts.title,
            subtitle: opts.subtitle || null,
            icon: opts.icon || null,
            relevance: Number(opts.relevance || 0),
            actions: actions,
            executable: opts.executable !== undefined ? !!opts.executable : true,
            expandable: !!opts.expandable || !!opts.completionText || !!(opts.metadata && opts.metadata.replaceQuery),
            metadata: opts.metadata || null
        };

        if (opts.enter)
            result.enter = opts.enter;
        else
            result.enter = ResultUtils.defaultEnterIntent(result, actions);

        if (opts.shiftEnter)
            result.shiftEnter = opts.shiftEnter;
        else if (opts.completionText)
            result.shiftEnter = { type: "replace-query", text: opts.completionText };
        else if (opts.metadata && opts.metadata.replaceQuery)
            result.shiftEnter = { type: "replace-query", text: opts.metadata.replaceQuery };
        else
            result.shiftEnter = { type: "noop" };

        return result;
    }
}
