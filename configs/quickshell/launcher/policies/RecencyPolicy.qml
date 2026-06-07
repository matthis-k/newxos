import QtQml
import "../" as Launcher
import "../logic/"

QtObject {
    function policyMatch(node, query, ctx) {
        if (query.isEmpty || !isFinite(node.lastUsedDaysAgo))
            return [];
        var rec = Evidence.recencyScore(node.lastUsedDaysAgo);
        return [{ strategy: "recency", field: "recency", fieldText: String(node.lastUsedDaysAgo), nodeId: node.id, kind: "recency", score: rec, weight: 0.08, effective: rec * 0.08, ranges: [], reason: "last used" }];
    }

    Component.onCompleted: {
        Launcher.PolicyRegistry.registerEvidence("recency", "own", policyMatch);
    }
}
