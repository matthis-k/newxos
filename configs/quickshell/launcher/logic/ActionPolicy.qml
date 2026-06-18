pragma Singleton
import Quickshell

Singleton {
    function defaultActionForNode(node, query, ownScore) {
        var actions = node.actionList || [];
        if (!node.switchActions) return actions[0] || null;

        var tokens = (query.tokens || []).map(function(t) { return t.normalized; });
        var best = { id: "", score: 0 };
        var aliases = {
            on: ["on", "enable", "connect"],
            off: ["off", "disable", "disconnect"],
            toggle: ["toggle", "switch"]
        };
        var switchAcronym = String(node.label || "").replace(/[^A-Za-z0-9]/g, "").charAt(0).toLowerCase();
        if (switchAcronym) {
            aliases.on.push(switchAcronym + "o");
            aliases.off.push(switchAcronym + "f");
            aliases.toggle.push(switchAcronym + "t");
        }
        for (var id in aliases) {
            for (var ti = 0; ti < tokens.length; ti += 1) {
                for (var ai = 0; ai < aliases[id].length; ai += 1) {
                    var alias = aliases[id][ai];
                    var token = tokens[ti];
                    var score = token === alias ? 1
                        : alias.indexOf(token) === 0 && token.length >= 2
                            ? 0.78 + token.length / Math.max(20, alias.length * 20)
                            : alias.length > token.length && alias.lastIndexOf(token) === alias.length - token.length
                                ? (token.length >= 2 ? 0.72 + token.length / Math.max(20, alias.length * 20) : 0.75)
                                : 0;
                    if (score > best.score) best = { id: id, score: score };
                }
            }
        }
        if (best.id && node.switchActions[best.id])
            return node.switchActions[best.id];
        return node.switchActions.toggle || actions[0] || null;
    }
}
