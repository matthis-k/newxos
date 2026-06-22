import QtQml
import "../" as Launcher
import "../logic/"

QtObject {
    Component.onCompleted: {
        Launcher.PolicyRegistry.registerTokenFlow("pass-all", function(node, query, ctx, args) {
            return TokenFlow.passAll(node, query, ctx, args);
        });

        Launcher.PolicyRegistry.registerTokenFlow("consume-own-pass-rest", function(node, query, ctx, args) {
            return TokenFlow.consumeOwnPassRest(node, query, ctx, args);
        });

        Launcher.PolicyRegistry.registerTokenFlow("claim-context-pass-all", function(node, query, ctx, args) {
            return TokenFlow.claimContextPassAll(node, query, ctx, args);
        });

        Launcher.PolicyRegistry.registerTokenFlow("consume-namespace-pass-rest", function(node, query, ctx, args) {
            return TokenFlow.consumeNamespacePassRest(node, query, ctx, args);
        });

        Launcher.PolicyRegistry.registerTokenFlow("consume-action-token", function(node, query, ctx, args) {
            return TokenFlow.consumeActionToken(node, query, ctx, args);
        });

        Launcher.PolicyRegistry.registerTokenFlow("consume-switch-pass-rest", function(node, query, ctx, args) {
            return TokenFlow.consumeSwitchPassRest(node, query, ctx, args);
        });

        Launcher.PolicyRegistry.registerTokenFlow("consume-path-segment", function(node, query, ctx, args) {
            return TokenFlow.consumePathSegment(node, query, ctx, args);
        });
    }
}
