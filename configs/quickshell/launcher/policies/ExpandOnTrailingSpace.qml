import QtQml
import "../" as Launcher
import "../logic/"

QtObject {
    property string policyId: "expand-on-trailing-space"

    function policyApply(childEval, parentEval, ctx, specArgs) {
        if (ctx.query.lastTokenEmpty) return true;

        var parentCov = Evidence.coveredTokenIndexes(parentEval.evidence || [], ctx.query);
        var childCov = Evidence.coveredTokenIndexes(childEval.evidence || [], ctx.query);

        for (var key in childCov) {
            if (key in parentCov) continue;
            return true;
        }
        return false;
    }

    Component.onCompleted: {
        Launcher.PolicyRegistry.registerChildVisible(policyId, policyApply);
    }
}
