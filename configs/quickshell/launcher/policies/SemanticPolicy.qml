import QtQml
import "../" as Launcher
import "../logic/"

QtObject {
    function policyMatch(node, query, ctx) {
        return Evidence.matchSemantic(node, query);
    }

    Component.onCompleted: {
        Launcher.PolicyRegistry.registerEvidence("semantic", "own", policyMatch);
    }
}
