import QtQml
import "../" as Launcher

QtObject {
    property string policyId
    property real margin: 0.03

    function policyApply(childEval, parentEval, ctx, specArgs) {
        var effectiveMargin = specArgs && specArgs.margin !== undefined
            ? Number(specArgs.margin)
            : margin;
        return (childEval.ownScore || 0) >= (parentEval.ownScore || 0) + effectiveMargin;
    }

    Component.onCompleted: {
        Launcher.PolicyRegistry.registerChildBypass(policyId, policyApply);
    }
}
