import QtQml
import "../" as Launcher

QtObject {
    property string policyId: "score-beats-parent"

    function policyApply(childEval, parentEval, ctx) {
        return (childEval.score || 0) > (parentEval.score || 0);
    }

    Component.onCompleted: {
        Launcher.PolicyRegistry.registerChildBypass(policyId, policyApply);
    }
}
