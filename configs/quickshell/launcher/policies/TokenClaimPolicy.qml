import QtQml
import "../" as Launcher
import "../logic/"

QtObject {
    function policyMatch(node, query, ctx) {
        if (!node.behavior || !node.behavior.tokenPolicy || !node.behavior.tokenPolicy.tokens || query.isEmpty)
            return [];
        var claims = Evidence.claimMatchingTokens(query, node.behavior.tokenPolicy.tokens, node.behavior.tokenPolicy);
        var out = [];
        for (var ci = 0; ci < claims.length; ci += 1)
            out.push(Evidence.tokenClaimToEvidence(node, query, claims[ci]));
        return out;
    }

    Component.onCompleted: {
        Launcher.PolicyRegistry.registerEvidence("token-claim", "own", policyMatch);
    }
}
