import QtQml
import Quickshell

LauncherBackendBase {
    id: root

    property string category: qsTr("Calculator")

    backendId: "calculator"
    name: qsTr("Calculator")
    helpTitle: qsTr("Calculator")
    helpDescription: qsTr("Evaluate math expressions")
    helpIcon: "accessories-calculator"
    helpPrefixes: ["@calc", "@calculator", "="]
    priority: 100
    maxResults: 1
    routes: [
        { pattern: "^@calc(ulator)?\\s+(.*)", mode: "exclusive" },
        { pattern: "^=\\s?(.*)", mode: "exclusive" },
        { pattern: "^.*$", mode: "ambient" }
    ]

    function isEnabled(query) {
        if (!root.enabled)
            return false;
        const expression = root.queryText(query);
        return expression.length > 0 && looksLikeMath(expression);
    }

    function looksLikeMath(expression) {
        const text = expression.trim().toLowerCase();
        if (!text)
            return false;

        if (/^(sqrt|sin|cos|tan|abs|floor|ceil|round)\s*\(/.test(text))
            return true;

        return /\d/.test(text) && /[+\-*/%^()]/.test(text) && /^[0-9+\-*/%^().,\s]+$/.test(text);
    }

    function tokenize(expression) {
        const tokens = [];
        const text = expression.replace(/,/g, ".").trim().toLowerCase();
        let index = 0;

        while (index < text.length) {
            const current = text[index];
            if (/\s/.test(current)) {
                index += 1;
                continue;
            }

            if (/[0-9.]/.test(current)) {
                let end = index + 1;
                while (end < text.length && /[0-9.]/.test(text[end]))
                    end += 1;
                const numberText = text.slice(index, end);
                const value = Number(numberText);
                if (!isFinite(value))
                    throw new Error("Invalid number");
                tokens.push({ type: "number", value: value });
                index = end;
                continue;
            }

            if (/[a-z]/.test(current)) {
                let end = index + 1;
                while (end < text.length && /[a-z]/.test(text[end]))
                    end += 1;
                tokens.push({ type: "name", value: text.slice(index, end) });
                index = end;
                continue;
            }

            if ("+-*/%^()".indexOf(current) >= 0) {
                tokens.push({ type: current, value: current });
                index += 1;
                continue;
            }

            throw new Error("Invalid character");
        }

        return tokens;
    }

    function parseExpression(tokens) {
        let index = 0;

        function peek() {
            return tokens[index] || null;
        }

        function consume(type) {
            const token = peek();
            if (!token || token.type !== type)
                return null;
            index += 1;
            return token;
        }

        function parsePrimary() {
            const token = peek();
            if (!token)
                throw new Error("Unexpected end");

            if (consume("+"))
                return parsePrimary();
            if (consume("-"))
                return -parsePrimary();

            if (token.type === "number") {
                index += 1;
                return token.value;
            }

            if (token.type === "name") {
                index += 1;
                const name = token.value;
                if (!consume("("))
                    throw new Error("Expected function call");
                const argument = parseAdditive();
                if (!consume(")"))
                    throw new Error("Expected closing parenthesis");
                return applyFunction(name, argument);
            }

            if (consume("(")) {
                const value = parseAdditive();
                if (!consume(")"))
                    throw new Error("Expected closing parenthesis");
                return value;
            }

            throw new Error("Unexpected token");
        }

        function parsePower() {
            let value = parsePrimary();
            while (consume("^") || consume("%")) {
                const op = tokens[index - 1].type;
                const right = parsePrimary();
                value = op === "^" ? Math.pow(value, right) : value % right;
            }
            return value;
        }

        function parseMultiplicative() {
            let value = parsePower();
            while (consume("*") || consume("/")) {
                const op = tokens[index - 1].type;
                const right = parsePower();
                value = op === "*" ? value * right : value / right;
            }
            return value;
        }

        function parseAdditive() {
            let value = parseMultiplicative();
            while (consume("+") || consume("-")) {
                const op = tokens[index - 1].type;
                const right = parseMultiplicative();
                value = op === "+" ? value + right : value - right;
            }
            return value;
        }

        const value = parseAdditive();
        if (index !== tokens.length)
            throw new Error("Unexpected trailing token");
        if (!isFinite(value))
            throw new Error("Invalid result");
        return value;
    }

    function applyFunction(name, argument) {
        switch (name) {
        case "sqrt": return Math.sqrt(argument);
        case "sin": return Math.sin(argument);
        case "cos": return Math.cos(argument);
        case "tan": return Math.tan(argument);
        case "abs": return Math.abs(argument);
        case "floor": return Math.floor(argument);
        case "ceil": return Math.ceil(argument);
        case "round": return Math.round(argument);
        default: throw new Error("Unsupported function");
        }
    }

    function evaluate(expression) {
        return parseExpression(tokenize(expression));
    }

    function formatResult(value) {
        const rounded = Math.round(value * 10000000000) / 10000000000;
        return rounded.toString();
    }

    function results(query) {
        const expression = root.queryText(query);
        if (!expression)
            return [];

        try {
            const output = formatResult(evaluate(expression));
            return [root.buildResult({
                id: "calc:" + expression,
                title: expression,
                subtitle: output,
                icon: "accessories-calculator",
                relevance: 1,
                actions: [
                    { id: "copy", label: qsTr("Copy result"), icon: "edit-copy", default: true },
                    { id: "copy-expression", label: qsTr("Copy expression"), icon: "edit-copy", default: false }
                ],
                metadata: { expression: expression, result: output }
            })];
        } catch (error) {
            return [];
        }
    }

    function activate(result, action) {
        const value = action && action.id === "copy-expression" ? result.metadata.expression : result.metadata.result;
        Quickshell.execDetached({ command: ["wl-copy", value] });
    }
}
