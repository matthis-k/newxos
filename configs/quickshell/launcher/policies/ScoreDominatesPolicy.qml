import QtQml
import "../" as Launcher

QtObject {
    property string policyId
    property real margin: 0.03

    function policyApply(childEval, parentEval, ctx) {
        return (childEval.score || 0) >= (parentEval.score || 0) + margin;
    }

    Component.onCompleted: {
        Launcher.PolicyRegistry.registerChildBypass(policyId, policyApply);
    }
}
