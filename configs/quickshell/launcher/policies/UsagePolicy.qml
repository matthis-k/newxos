import QtQml
import "../" as Launcher
import "../logic/"

QtObject {
    function policyMatch(node, query, ctx) {
        if (query.isEmpty || !node.usageCount || node.usageCount <= 0)
            return [];
        var usage = Evidence.frequencyScore(node.usageCount);
        return [{ strategy: "usage", field: "usage", fieldText: String(node.usageCount), nodeId: node.id, kind: "frequency", score: usage, weight: 0.12, effective: usage * 0.12, ranges: [], reason: "usage frequency" }];
    }

    Component.onCompleted: {
        Launcher.PolicyRegistry.registerEvidence("usage", "own", policyMatch);
    }
}
