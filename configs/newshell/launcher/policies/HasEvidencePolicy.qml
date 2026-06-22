import QtQml
import "../" as Launcher

QtObject {
    property string policyId: "has-evidence"

    function policyApply(childEval, parentEval, ctx, specArgs) {
        return (childEval.ownEvidence || []).length > 0 || (childEval.inheritedEvidence || []).length > 0;
    }

    Component.onCompleted: {
        Launcher.PolicyRegistry.registerChildVisible(policyId, policyApply);
    }
}
