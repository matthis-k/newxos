import QtQml
import "../logic/CompositeSearch.js" as CompositeSearch

LauncherBackendBase {
    id: root

    default property list<QtObject> nodes

    property var treeRoots: []
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

    function rootNode(query, context) {
        const roots = root.effectiveTreeRoots();
        const cacheKey = root.backendId + ":" + roots.length;
        if (!root.dynamicCompositeRoot && root.compositeRootCache && root.compositeRootCacheKey === cacheKey)
            return root.compositeRootCache;

        root.compositeRootCacheKey = cacheKey;
        const compositeRoot = root.backendRootDto(roots.map(function(node) { return compositeNode(node, []); }), {
            tags: [root.backendId],
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

    function effectiveTreeRoots() {
        var roots = [];
        for (var i = 0; i < (root.treeRoots || []).length; i += 1)
            roots.push(materializeTreeNode(root.treeRoots[i]));
        for (var ni = 0; ni < root.nodes.length; ni += 1) {
            var node = root.nodes[ni];
            if (node && typeof node.toTreeObject === "function")
                roots.push(node.toTreeObject());
        }
        return roots.filter(Boolean);
    }

    function materializeTreeNode(node) {
        return node && typeof node.toTreeObject === "function" ? node.toTreeObject() : node;
    }

    function compositeNode(node, path) {
        const children = (node.children || []).map(function(child) {
            return compositeNode(child, path.concat([node]));
        });
        const action = defaultAction(node);
        const switchActions = node.switchState === undefined ? null : switchActionMap(node, children);
        const kind = switchActions ? "switch" : children.length > 0 ? "action-group" : "desktop-action";
        const actions = switchActions
            ? [switchActions.toggle, switchActions.on, switchActions.off].filter(Boolean)
            : action ? [root.actionDto(action.actionId || action.id || "run", action.title || qsTr("Run"), action)] : [];

        const nodeBehavior = behaviorForNode(node, children);
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

        return root.nodeDto({
            id: root.backendId + ":" + path.concat([node]).map(function(item) { return item.id || item.title; }).join(":"),
            kind: kind,
            label: node.title || node.id,
            subtitle: node.subtitle || "",
            icon: node.icon || root.helpIcon || "system-search",
            iconColor: node.iconColor || null,
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
                flattenPolicy: flattenPolicy,
                displayPolicy: nodeBehavior.displayPolicy || null
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

    function behaviorForNode(node, children) {
        if (node.behavior)
            return node.behavior;
        if (node.template === "action-group" || node.template === "flat-action-group")
            return categoryGroupBehavior(node.groupOptions || {});
        return {};
    }

    function switchActionMap(node, children) {
        const byState = {};
        for (const child of children || []) {
            const leafAction = child.actionList && child.actionList[0];
            const payload = leafAction && leafAction.payload || {};
            const id = String(child.label || child.id || "").toLowerCase();
            if (!leafAction)
                continue;
            if (!byState.toggle && (payload.state === null || id.indexOf("toggle") >= 0))
                byState.toggle = root.actionDto("toggle", qsTr("Toggle"), leafAction.payload || leafAction);
            else if (!byState.off && (payload.state === false || payload.state === "disconnect" || id.indexOf("off") >= 0 || id.indexOf("disable") >= 0 || id.indexOf("disconnect") >= 0))
                byState.off = root.actionDto("off", qsTr("Off"), leafAction.payload || leafAction);
            else if (!byState.on && (payload.state === true || payload.state === "connect" || id.indexOf("on") >= 0 || id.indexOf("enable") >= 0 || id.indexOf("connect") >= 0))
                byState.on = root.actionDto("on", qsTr("On"), leafAction.payload || leafAction);
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
            iconColor: opts.iconColor || null,
            action: actionPayload(actionId, opts.actionProps || {}, opts.execute),
            dangerous: !!opts.dangerous,
            behavior: opts.behavior || null,
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
                    flattenAllChildrenOnParentMatch: !!opts.flattenAllChildrenOnParentMatch,
                    parentMatchMinScore: opts.parentMatchMinScore === undefined ? 0.25 : opts.parentMatchMinScore,
                    maxNestedChildren: opts.maxNestedChildren
                }
            },
            displayPolicy: opts.displayPolicy || (opts.breadcrumbMode ? { breadcrumbMode: opts.breadcrumbMode } : null)
        };
    }

    function originalNodeForPath(commandPath) {
        var nodes = root.effectiveTreeRoots();
        var current = null;
        for (var i = 0; i < (commandPath || []).length; i += 1) {
            var wanted = commandPath[i];
            current = null;
            for (var ni = 0; ni < nodes.length; ni += 1) {
                var candidate = nodes[ni];
                if ((candidate.id || candidate.title) === wanted) {
                    current = candidate;
                    break;
                }
            }
            if (!current)
                return null;
            nodes = current.children || [];
        }
        return current;
    }

    function actionPayloadForPath(commandPath, actionId) {
        var node = originalNodeForPath(commandPath);
        if (!node)
            return null;

        var ownAction = node.defaultAction || node.action || null;
        if (ownAction && (!actionId || ownAction.actionId === actionId || ownAction.id === actionId))
            return ownAction;

        for (var i = 0; i < (node.children || []).length; i += 1) {
            var child = node.children[i];
            var childAction = child.defaultAction || child.action || null;
            if (childAction && (child.id === actionId || childAction.actionId === actionId || childAction.id === actionId))
                return childAction;
        }

        return ownAction;
    }

}
