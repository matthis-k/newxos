import QtQml
import "../" as Launcher

QtObject {
    property string policyId: "visible-flag"

    function policyApply(childEval, parentEval, ctx, specArgs) {
        return childEval.visible === true;
    }

    Component.onCompleted: {
        Launcher.PolicyRegistry.registerChildVisible(policyId, policyApply);
    }
}
