import QtQml
import "../" as Launcher

QtObject {
    property string policyId: "candidate-or-visible"

    function policyApply(childEval, parentEval, ctx) {
        return childEval.candidate === true || childEval.visible === true;
    }

    Component.onCompleted: {
        Launcher.PolicyRegistry.registerChildVisible(policyId, policyApply);
    }
}
