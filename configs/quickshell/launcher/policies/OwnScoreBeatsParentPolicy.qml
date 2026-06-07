import QtQml
import "../" as Launcher

QtObject {
    property string policyId: "own-score-beats-parent"

    function policyApply(childEval, parentEval, ctx) {
        return (childEval.ownScore || 0) > (parentEval.ownScore || 0);
    }

    Component.onCompleted: {
        Launcher.PolicyRegistry.registerChildVisible(policyId, policyApply);
        Launcher.PolicyRegistry.registerChildBypass(policyId, policyApply);
    }
}
