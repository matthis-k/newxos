import QtQml

QtObject {
    id: root

    function makeAction(id, label, payload) {
        return { id: id, label: label || id, icon: null, default: false, payload: payload || null };
    }

    function makeNode(props) {
        var node = props || {};
        if (node.__compositePrepared) return node;
        node.id = node.id || "";
        node.backendId = node.backendId || "";
        node.kind = node.kind || "node";
        node.label = node.label || node.title || "";
        node.title = node.label;
        node.subtitle = node.subtitle || "";
        node.icon = node.icon || null;
        node.iconColor = node.iconColor || null;
        node.children = node.children || node._children || [];
        node.aliases = node.aliases || [];
        node.keywords = node.keywords || [];
        node.tags = node.tags || [];
        node.fieldWeights = node.fieldWeights || {};
        node.behavior = node.behavior || {};
        node.semanticTerms = node.semanticTerms || [];
        node.semanticBoostRequiresAny = node.semanticBoostRequiresAny || [];
        node.command = node.command || "";
        node.path = node.path || "";
        node.usageCount = node.usageCount || 0;
        node.lastUsedDaysAgo = node.lastUsedDaysAgo === undefined ? 9999 : node.lastUsedDaysAgo;
        node.evaluationProfile = node.evaluationProfile || { mode: "generic+custom", strategies: ["exact", "prefix", "compact", "substring", "acronym", "fuzzy", "semantic", "usage", "recency"], scorePolicy: "default", profile: { evidence: ["field-match:all", "switch-action", "semantic", "token-claim", "usage", "recency"], inherit: ["path-evidence"], boost: ["descendant-boost"], childVisible: ["visible-flag"], childBypass: ["own-score-beats-parent", "score-dominates:0.03"], tokenFlow: ["pass-all"], defaultAction: ["default-action-owner"], riskGate: ["risk-gate"] } };
        node.actionList = node.actionList || [];
        node.meta = node.meta || node.metadata || {};
        for (var i = 0; i < node.children.length; i += 1) {
            node.children[i] = root.makeNode(node.children[i]);
            node.children[i].parent = node;
        }
        node.__compositePrepared = true;
        return node;
    }
}
