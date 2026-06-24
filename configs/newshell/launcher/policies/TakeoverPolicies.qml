import QtQml
import "../" as Launcher
import "../logic/"

QtObject {
    Component.onCompleted: {
        Launcher.PolicyRegistry.registerTakeoverRequest("explicit-child-token", function(childEv, parentEv, ctx, args) {
            return TakeoverEngine.explicitChildToken(childEv, parentEv, ctx, args);
        });

        Launcher.PolicyRegistry.registerTakeoverRequest("child-own-match-parent-no-own-match", function(childEv, parentEv, ctx, args) {
            return TakeoverEngine.childOwnMatchParentNoOwnMatch(childEv, parentEv, ctx, args);
        });

        Launcher.PolicyRegistry.registerTakeoverRequest("child-covers-passed-tokens", function(childEv, parentEv, ctx, args) {
            return TakeoverEngine.childCoversPassedTokens(childEv, parentEv, ctx, args);
        });

        Launcher.PolicyRegistry.registerTakeoverRequest("own-score-dominates-takeover", function(childEv, parentEv, ctx, args) {
            return TakeoverEngine.ownScoreDominatesTakeover(childEv, parentEv, ctx, args);
        });

        Launcher.PolicyRegistry.registerTakeoverRequest("exact-action-token-takeover", function(childEv, parentEv, ctx, args) {
            return TakeoverEngine.exactActionTokenTakeover(childEv, parentEv, ctx, args);
        });

        Launcher.PolicyRegistry.registerTakeoverAccept("accept-dominated-claims", function(parentEv, claims, ctx, args) {
            return TakeoverEngine.defaultAcceptPolicy(parentEv, claims, ctx, args);
        });

        Launcher.PolicyRegistry.registerTakeoverAccept("accept-all-claims", function(parentEv, claims, ctx, args) {
            if (!claims || !claims.length) return { accepted: false, reason: "no claims" };
            var best = claims[0];
            return {
                accepted: true,
                ownerId: best.claimantId,
                representation: "promote-child",
                retainParent: false,
                suppressParentActions: true,
                selectedOwnerId: best.claimantId,
                defaultActionOwnerId: best.claimantId,
                activation: "normal",
                reason: "accept-all-claims: accepted claim from " + best.claimantId
            };
        });

        Launcher.PolicyRegistry.registerTakeoverAccept("accept-explicit-claims", function(parentEv, claims, ctx, args) {
            if (!claims || !claims.length) return { accepted: false, reason: "no claims" };
            var explicitClaims = claims.filter(function(c) { return c.strength >= 0.7; });
            if (explicitClaims.length === 0) return { accepted: false, reason: "no explicit claims (strength < 0.7)" };
            var best = explicitClaims[0];
            return {
                accepted: true,
                ownerId: best.claimantId,
                representation: "promote-child",
                retainParent: false,
                suppressParentActions: true,
                selectedOwnerId: best.claimantId,
                defaultActionOwnerId: best.claimantId,
                activation: "normal",
                reason: "accept-explicit-claims: accepted strong claim from " + best.claimantId
            };
        });
    }
}
