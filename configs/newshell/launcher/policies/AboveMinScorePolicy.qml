import QtQml
import "../" as Launcher

QtObject {
    property string policyId
    property real threshold: 0.25

    function policyApply(childEval, parentEval, ctx, specArgs) {
        var effectiveThreshold = specArgs && specArgs.threshold !== undefined
            ? Number(specArgs.threshold)
            : threshold;
        return (childEval.score || 0) >= effectiveThreshold;
    }

    Component.onCompleted: {
        Launcher.PolicyRegistry.registerChildVisible(policyId, policyApply);
    }
}
