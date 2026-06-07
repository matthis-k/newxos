import QtQml
import "../" as Launcher

QtObject {
    property string policyId
    property real margin: 0.03

    function policyApply(childEval, parentEval, ctx) {
        return (childEval.ownScore || 0) >= (parentEval.ownScore || 0) + margin;
    }

    Component.onCompleted: {
        Launcher.PolicyRegistry.registerChildBypass(policyId, policyApply);
    }
}
