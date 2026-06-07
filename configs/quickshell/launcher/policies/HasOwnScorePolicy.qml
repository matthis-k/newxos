import QtQml
import "../" as Launcher

QtObject {
    property string policyId: "has-own-score"

    function policyApply(childEval, parentEval, ctx) {
        return (childEval.ownScore || 0) > 0;
    }

    Component.onCompleted: {
        Launcher.PolicyRegistry.registerChildVisible(policyId, policyApply);
    }
}
