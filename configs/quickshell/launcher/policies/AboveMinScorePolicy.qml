import QtQml
import "../" as Launcher

QtObject {
    property string policyId
    property real threshold: 0.25

    function policyApply(childEval, parentEval, ctx) {
        return (childEval.score || 0) >= threshold;
    }

    Component.onCompleted: {
        Launcher.PolicyRegistry.registerChildVisible(policyId, policyApply);
    }
}
