pragma Singleton
import QtQml
import Quickshell
import qs.services

Singleton {
    readonly property var prof: Profiler.scope("launcher.policyDiagnostics", { category: "launcher" })
    readonly property var tracer: Logger.scope("launcher.policyDiagnostics", { category: "launcher" })

    function empty() {
        return { warnings: [], errors: [], info: [], unresolved: [], timings: {} };
    }

    function warn(diag, msg) {
        tracer.trace("warn", function() { return { msg: msg }; });
        if (diag) diag.warnings = diag.warnings.concat([String(msg)]);
    }

    function error(diag, msg) {
        tracer.warn("error", function() { return { msg: msg }; });
        if (diag) diag.errors = diag.errors.concat([String(msg)]);
    }

    function info(diag, msg) {
        tracer.trace("info", function() { return { msg: msg }; });
        if (diag) diag.info = diag.info.concat([String(msg)]);
    }

    function unresolved(diag, name) {
        tracer.trace("unresolved", function() { return { name: name }; });
        if (diag) diag.unresolved = diag.unresolved.concat([String(name)]);
    }

    function markTiming(diag, key, ms) {
        if (diag) diag.timings[key] = (diag.timings[key] || 0) + ms;
    }

    function hasIssues(diag) {
        return diag && (diag.errors.length > 0 || diag.warnings.length > 0);
    }

    function summary(diag) {
        if (!diag) return "no diagnostics";
        var parts = [];
        if (diag.errors.length) parts.push(diag.errors.length + " errors");
        if (diag.warnings.length) parts.push(diag.warnings.length + " warnings");
        if (diag.unresolved.length) parts.push(diag.unresolved.length + " unresolved");
        if (!parts.length) return "ok";
        return parts.join(", ");
    }

    function toDebug(diag) {
        if (!diag) return { warnings: [], errors: [], unresolved: [] };
        return {
            warnings: diag.warnings.slice(),
            errors: diag.errors.slice(),
            unresolved: diag.unresolved.slice(),
            timings: Object.assign({}, diag.timings || {})
        };
    }
}
