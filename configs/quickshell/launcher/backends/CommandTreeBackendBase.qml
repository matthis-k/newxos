import QtQml
import "../logic/CommandTree.js" as CommandTree
import "../logic/Router.js" as Router
import "../logic/CompositeSearch.js" as CompositeSearch

LauncherBackendBase {
    id: root

    property var treeRoots: []
    property var treePrefixes: []
    property var controller: null
    property var compositeRootCache: null
    property string compositeRootCacheKey: ""
    property bool prewarmCompositeRootCache: true

    Component.onCompleted: {
        if (root.prewarmCompositeRootCache)
            Qt.callLater(root.prewarmCompositeRoot);
    }

    function prewarmCompositeRoot() {
        if (root.enabled)
            root.rootNode({ raw: "" }, {});
    }

    function results(query) {
        const prefixes = resolvePrefixes(query);
        const results = CommandTree.suggest(query, prefixes, root.treeRoots).map(result => {
            result.source = root.backendId;
            result.category = root.category;
            if (result.children && result.children.length > 0) {
                result.children.sort((a, b) => (b.relevance || 0) - (a.relevance || 0) || a.title.localeCompare(b.title));
            }
            return result;
        });

        const seen = {};
        const unique = [];
        for (const r of results) {
            const key = r.title || r.id;
            if (!seen[key]) {
                seen[key] = true;
                unique.push(r);
            }
        }
        return unique.slice(0, root.maxResults);
    }

    function rootNode(query, context) {
        const match = root.matchQuery(query ? query.raw : "");
        const cacheKey = root.backendId + ":" + (root.treeRoots || []).length;
        if (root.compositeRootCache && root.compositeRootCacheKey === cacheKey)
            return root.compositeRootCache;

        root.compositeRootCacheKey = cacheKey;
        root.compositeRootCache = CompositeSearch.makeNode({
            id: "backend." + root.backendId,
            backendId: root.backendId,
            backendPriority: root.priority,
            kind: "backend",
            label: root.helpTitle || root.name || root.backendId,
            subtitle: root.helpDescription || "",
            icon: root.helpIcon || "system-search",
            tags: [root.backendId],
            children: (root.treeRoots || []).map(function(node) { return compositeNode(node, []); }),
            evaluationProfile: { mode: "generic", strategies: ["exact", "prefix", "compact", "substring", "acronym"], scorePolicy: "backend" }
        });
        CompositeSearch.buildSearchIndex(root.compositeRootCache);
        return root.compositeRootCache;
    }

    function invalidateCompositeRootCache() {
        root.compositeRootCache = null;
        root.compositeRootCacheKey = "";
    }

    function compositeNode(node, path) {
        const children = (node.children || []).map(function(child) {
            return compositeNode(child, path.concat([node]));
        });
        const action = defaultAction(node);
        const switchActions = switchActionMap(node, children);
        const kind = switchActions ? "switch" : children.length > 0 ? (action ? "action-group" : "action-group") : "desktop-action";
        const actions = switchActions
            ? [switchActions.toggle, switchActions.on, switchActions.off].filter(Boolean)
            : action ? [CompositeSearch.makeAction(action.actionId || action.id || "run", action.title || qsTr("Run"), action)] : [];

        return CompositeSearch.makeNode({
            id: root.backendId + ":" + path.concat([node]).map(function(item) { return item.id || item.title; }).join(":"),
            backendId: root.backendId,
            kind: kind,
            label: node.title || node.id,
            subtitle: node.subtitle || "",
            icon: node.icon || root.helpIcon || "system-search",
            aliases: node.aliases || [],
            keywords: node.keywords || [],
            tags: [root.backendId, root.category || ""].filter(Boolean),
            actionList: actions,
            switchActions: switchActions,
            switchState: node.switchState === undefined ? null : node.switchState,
            dangerous: !!node.dangerous,
            children: children,
            usageCount: node.usageCount || 0,
            lastUsedDaysAgo: node.lastUsedDaysAgo === undefined ? 9999 : node.lastUsedDaysAgo,
            behavior: {
                tokenPolicy: node.tokenPolicy ? node.tokenPolicy : node.aliases && node.aliases.length ? { tokens: node.aliases, weight: 0.62 } : null,
                flattenPolicy: children.length > 0 ? {
                    modeHint: "group-dominance",
                    priority: root.priority || 0,
                    groupDisplay: {
                        parentWinsMargin: 0.08,
                        childWinsMargin: 0.03,
                        childDominatesMargin: 0.18,
                        maxFlattenedChildren: 3,
                        minChildScore: 0.25,
                        showGroupHeaderInFilteredMode: true
                    }
                } : null
            },
            semanticTerms: semanticTermsForNode(node),
            evaluationProfile: { mode: "generic+custom", strategies: ["exact", "prefix", "compact", "substring", "acronym", "semantic", "usage", "recency"], scorePolicy: "default" },
            meta: {
                action: action,
                commandPath: path.concat([node]).map(function(item) { return item.id || item.title; }),
                replaceQuery: node.replaceQuery || null
            }
        });
    }

    function defaultAction(node) {
        return node.defaultAction || node.action || null;
    }

    function switchActionMap(node, children) {
        const byState = {};
        for (const child of children || []) {
            const leafAction = child.actionList && child.actionList[0];
            const id = String(child.label || child.id || "").toLowerCase();
            if (!leafAction)
                continue;
            if (id.indexOf("toggle") >= 0)
                byState.toggle = CompositeSearch.makeAction("toggle", qsTr("Toggle"), leafAction.payload || leafAction);
            else if (id.indexOf("on") >= 0 || id.indexOf("enable") >= 0 || id.indexOf("connect") >= 0)
                byState.on = CompositeSearch.makeAction("on", qsTr("On"), leafAction.payload || leafAction);
            else if (id.indexOf("off") >= 0 || id.indexOf("disable") >= 0 || id.indexOf("disconnect") >= 0)
                byState.off = CompositeSearch.makeAction("off", qsTr("Off"), leafAction.payload || leafAction);
        }
        return byState.on && byState.off && byState.toggle ? byState : null;
    }

    function semanticTermsForNode(node) {
        const aliases = node.aliases || [];
        return aliases.map(function(alias) {
            return { triggers: [String(alias).toLowerCase()], matches: [String(alias).toLowerCase(), String(node.title || "").toLowerCase()], field: "semantic", score: 0.74, weight: 0.32 };
        });
    }

    function resolvePrefixes(query) {
        const raw = String(query || "").trim();
        for (const prefix of root.treePrefixes || []) {
            if (prefix && raw.startsWith(prefix))
                return root.treePrefixes;
        }
        return [""];
    }

    function isEnabled(query) {
        if (!root.enabled)
            return false;
        for (const route of root.routes || []) {
            if (Router.routeMatches(query, route))
                return true;
        }
        return false;
    }
}
