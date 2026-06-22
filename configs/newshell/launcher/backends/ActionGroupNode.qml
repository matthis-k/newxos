Node {
    template: "action-group"

    function defaultGroupProfile() {
        return {
            mode: "generic+custom",
            strategies: ["exact", "prefix", "compact", "substring", "acronym", "fuzzy", "semantic", "usage", "recency"],
            scorePolicy: "default",
            profile: {
                evidence: [["field-match", { filterType: "all" }], "switch-action", "semantic", "token-claim", "usage", "recency"],
                boost: ["descendant-boost"],
                childVisible: ["visible-flag"],
                tokenFlow: ["consume-namespace-pass-rest"],
                takeoverRequest: [
                    "child-own-match-parent-no-own-match",
                    "explicit-child-token",
                    "child-covers-passed-tokens",
                    "own-score-dominates-takeover"
                ],
                takeoverAccept: ["accept-dominated-claims"],
                expand: ["expand-on-own-match-or-trailing-space"],
                retainParent: [{ name: "retain-parent-when", args: { condition: "own-match" } }],
                defaultAction: ["default-action-expand"],
                riskGate: ["risk-gate"]
            }
        };
    }

    function toTreeObject() {
        var base = Node.prototype.toTreeObject.call(this);
        if (!base.evaluationProfile && !this.evaluationProfile)
            base.evaluationProfile = defaultGroupProfile();
        return base;
    }
}
