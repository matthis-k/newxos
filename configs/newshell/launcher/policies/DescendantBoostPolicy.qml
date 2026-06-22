import QtQml
import "../" as Launcher
import "../logic/"

QtObject {
    property string policyId
    property string factor: "auto"

    function policyApply(node, query, ctx, evaluatedChildren, scores) {
        var directiveActive = !!(ctx.directive && ctx.directive.active);
        var ownScore = scores ? scores.ownScore || 0 : 0;
        var groupDisplay = node.behavior && node.behavior.flattenPolicy && node.behavior.flattenPolicy.groupDisplay || {};
        var keepAllChildren = (groupDisplay.showAllChildrenOnParentMatch || groupDisplay.flattenAllChildrenOnParentMatch) && false;

        var retained = (evaluatedChildren || []).filter(function(c) {
            return keepAllChildren || c.candidate || c.visible || ctx.showHidden;
        });

        var bestChildScore = 0;
        var bestChildMatchDepth = 9999;
        for (var b = 0; b < retained.length; b += 1) {
            if (retained[b].visible || ctx.showHidden) {
                if (retained[b].score > bestChildScore + 0.0001) {
                    bestChildScore = retained[b].score;
                    bestChildMatchDepth = (retained[b].matchDepth === undefined ? 0 : retained[b].matchDepth) + 1;
                } else if (Math.abs(retained[b].score - bestChildScore) <= 0.0001) {
                    bestChildMatchDepth = Math.min(bestChildMatchDepth, (retained[b].matchDepth === undefined ? 0 : retained[b].matchDepth) + 1);
                }
            }
        }
        if (bestChildScore <= 0)
            return 0;

        var depthPenalty = bestChildMatchDepth < 9999 ? Math.pow(0.92, bestChildMatchDepth) : 1;
        var factorVal;
        if (factor !== "auto") {
            factorVal = Tokenize.clamp(parseFloat(factor), 0, 1);
            factorVal = isFinite(factorVal) ? factorVal : 0.28;
        } else {
            factorVal = node.switchActions ? (ownScore > 0 ? 1 : 0.82)
                : node.kind === "backend" ? 0.82
                : node.behavior && node.behavior.filterable ? 1.0
                : 0.28;
        }

        return bestChildScore * depthPenalty * factorVal;
    }

    Component.onCompleted: {
        Launcher.PolicyRegistry.registerBoost(policyId, policyApply);
    }
}
