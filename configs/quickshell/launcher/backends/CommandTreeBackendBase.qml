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
    property bool dynamicCompositeRoot: false

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
        if (!root.dynamicCompositeRoot && root.compositeRootCache && root.compositeRootCacheKey === cacheKey)
            return root.compositeRootCache;

        root.compositeRootCacheKey = cacheKey;
        const compositeRoot = CompositeSearch.makeNode({
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
        CompositeSearch.buildSearchIndex(compositeRoot);
        if (!root.dynamicCompositeRoot)
            root.compositeRootCache = compositeRoot;
        return compositeRoot;
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

        const nodeBehavior = node.behavior || {};
        const flattenPolicy = nodeBehavior.flattenPolicy || (children.length > 0 ? {
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
        } : null);

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
            showWhenQueryEmpty: path.length === 0,
            usageCount: node.usageCount || 0,
            lastUsedDaysAgo: node.lastUsedDaysAgo === undefined ? 9999 : node.lastUsedDaysAgo,
            behavior: {
                tokenPolicy: node.tokenPolicy ? node.tokenPolicy : node.aliases && node.aliases.length ? { tokens: node.aliases, weight: 0.62 } : null,
                flattenPolicy: flattenPolicy
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
            else if (id.indexOf("off") >= 0 || id.indexOf("disable") >= 0 || id.indexOf("disconnect") >= 0)
                byState.off = CompositeSearch.makeAction("off", qsTr("Off"), leafAction.payload || leafAction);
            else if (id.indexOf("on") >= 0 || id.indexOf("enable") >= 0 || id.indexOf("connect") >= 0)
                byState.on = CompositeSearch.makeAction("on", qsTr("On"), leafAction.payload || leafAction);
        }
        return byState.on && byState.off && byState.toggle ? byState : null;
    }

    function semanticTermsForNode(node) {
        const aliases = node.aliases || [];
        return aliases.map(function(alias) {
            return { triggers: [String(alias).toLowerCase()], matches: [String(alias).toLowerCase(), String(node.title || "").toLowerCase()], field: "semantic", score: 0.74, weight: 0.32 };
        });
    }

    function actionPayload(actionId, props, executor) {
        var payload = Object.assign({ actionId: actionId }, props || {});
        if (executor)
            payload.execute = executor;
        return payload;
    }

    function actionNode(options) {
        var opts = options || {};
        var actionId = opts.actionId || opts.id || "run";
        return {
            id: opts.id || actionId,
            aliases: opts.aliases || [],
            title: opts.title || opts.id || actionId,
            subtitle: opts.subtitle || "",
            icon: opts.icon || root.helpIcon || "system-run",
            action: actionPayload(actionId, opts.actionProps || {}, opts.execute),
            dangerous: !!opts.dangerous,
            behavior: opts.behavior || null,
            children: opts.children || []
        };
    }

    function groupNode(options) {
        var opts = options || {};
        return {
            id: opts.id,
            aliases: opts.aliases || [],
            title: opts.title || opts.id,
            subtitle: opts.subtitle || "",
            icon: opts.icon || root.helpIcon || "folder",
            behavior: opts.behavior || (opts.showAllChildrenOnParentMatch ? categoryGroupBehavior(opts.groupDisplay || {}) : null),
            defaultAction: opts.defaultAction || null,
            action: opts.action || null,
            switchState: opts.switchState,
            children: opts.children || []
        };
    }

    function categoryGroupBehavior(options) {
        var opts = options || {};
        return {
            flattenPolicy: {
                modeHint: "group-dominance",
                priority: opts.priority === undefined ? root.priority || 0 : opts.priority,
                groupDisplay: {
                    parentWinsMargin: opts.parentWinsMargin === undefined ? 0.08 : opts.parentWinsMargin,
                    childWinsMargin: opts.childWinsMargin === undefined ? 0.03 : opts.childWinsMargin,
                    childDominatesMargin: opts.childDominatesMargin === undefined ? 0.18 : opts.childDominatesMargin,
                    maxFlattenedChildren: opts.maxFlattenedChildren === undefined ? 3 : opts.maxFlattenedChildren,
                    minChildScore: opts.minChildScore === undefined ? 0.25 : opts.minChildScore,
                    showGroupHeaderInFilteredMode: opts.showGroupHeaderInFilteredMode === undefined ? true : opts.showGroupHeaderInFilteredMode,
                    showAllChildrenOnParentMatch: opts.showAllChildrenOnParentMatch === undefined ? true : opts.showAllChildrenOnParentMatch,
                    parentMatchMinScore: opts.parentMatchMinScore === undefined ? 0.25 : opts.parentMatchMinScore,
                    maxNestedChildren: opts.maxNestedChildren
                }
            }
        };
    }

    function booleanBinding(getter, setter) {
        return { get: getter, set: setter };
    }

    function booleanSwitchNode(options) {
        var opts = options || {};
        var actionId = opts.actionId || opts.id;
        return groupNode({
            id: opts.id,
            aliases: opts.aliases || [],
            title: opts.title || opts.id,
            subtitle: opts.subtitle || "",
            icon: opts.icon || "view-refresh-symbolic",
            switchState: readBooleanSwitch(opts.binding),
            children: booleanSwitchChildren(actionId, opts.binding, opts.dangerousOff)
        });
    }

    function booleanSwitchChildren(actionId, binding, dangerousOff) {
        var acronymPrefix = String(actionId || "").replace(/[^A-Za-z0-9]/g, "").charAt(0).toLowerCase();
        return [
            actionNode({ id: "on", aliases: [acronymPrefix + "o"], title: qsTr("Turn On"), icon: "object-select-symbolic", actionId: actionId, actionProps: { state: true }, execute: function() { writeBooleanSwitch(binding, true); } }),
            actionNode({ id: "off", aliases: [acronymPrefix + "f"], title: qsTr("Turn Off"), icon: "window-close-symbolic", actionId: actionId, actionProps: { state: false }, execute: function() { writeBooleanSwitch(binding, false); }, dangerous: dangerousOff === undefined ? actionId !== "dnd" : !!dangerousOff }),
            actionNode({ id: "toggle", aliases: [acronymPrefix + "t"], title: qsTr("Toggle"), icon: "view-refresh-symbolic", actionId: actionId, actionProps: { state: null }, execute: function() { writeBooleanSwitch(binding, null); } })
        ];
    }

    function readBooleanSwitch(binding) {
        if (!binding || typeof binding.get !== "function")
            return null;
        var value = binding.get();
        return value === null || value === undefined ? null : !!value;
    }

    function writeBooleanSwitch(binding, state) {
        if (!binding || typeof binding.set !== "function")
            return;
        var current = readBooleanSwitch(binding);
        var enabled = state === null ? !current : state;
        binding.set(!!enabled);
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
