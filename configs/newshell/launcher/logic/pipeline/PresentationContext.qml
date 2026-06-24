pragma Singleton
import QtQml
import Quickshell
import qs.services

Singleton {
    readonly property var prof: Profiler.scope("launcher.presentationContext", { category: "launcher" })
    readonly property var tracer: Logger.scope("launcher.presentationContext", { category: "launcher" })

    function forShapedItem(ev, decision, parentContext) {
        var placement = decision && decision.placement || "standalone";
        tracer.trace("forShapedItem", function() { return { nodeId: ev && ev.node && ev.node.id, placement: placement }; });
        var chain = collectParentChain(ev && ev.node || null);
        var breadcrumbs = chain.map(function(n) { return n.label; });

        return {
            placement: placement,
            parentShown: !!(decision && decision.showParent),
            ancestorsShown: parentContext ? parentContext.ancestorsShown && parentContext.parentShown : true,
            showBreadcrumbs: shouldShowBreadcrumbs(placement, breadcrumbs, decision),
            showBackendBadge: shouldShowBackendBadge(placement, ev),
            showActionHint: shouldShowActionHint(placement, ev),
            density: densityFor(placement, ev),
            breadcrumbs: breadcrumbs,
            breadcrumbText: formatBreadcrumbs(breadcrumbs, placement, ev)
        };
    }

    function collectParentChain(node) {
        var chain = [];
        var cur = node;
        while (cur && cur.kind !== "root") {
            chain.unshift(cur);
            cur = cur.parent;
        }
        return chain;
    }

    function shouldShowBreadcrumbs(placement, breadcrumbs, decision) {
        switch (placement) {
        case "group-child":
            return false;
        case "group":
            return false;
        case "promoted-child":
            return breadcrumbs.length > 0;
        case "flattened":
            return breadcrumbs.length > 0;
        case "standalone":
            return breadcrumbs.length > 1;
        case "nested-group":
            return false;
        case "filtered-group":
            return false;
        default:
            return breadcrumbs.length > 1;
        }
    }

    function shouldShowBackendBadge(placement, ev) {
        if (placement === "group" || placement === "nested-group")
            return false;
        if (!ev || !ev.node) return false;
        var backendId = ev.node.backendId || "";
        if (backendId === "desktop" || backendId === "backends")
            return false;
        return true;
    }

    function shouldShowActionHint(placement, ev) {
        if (placement === "group" || placement === "nested-group")
            return false;
        if (!ev || !ev.node) return false;
        return !!(ev.node.actionList && ev.node.actionList.length > 0) || !!ev.node.switchActions;
    }

    function densityFor(placement, ev) {
        if (placement === "group" || placement === "nested-group")
            return "compact";
        if (!ev || !ev.node) return "normal";
        if (ev.node.switchActions) return "compact";
        if (ev.node.kind === "app-entry") return "normal";
        if (ev.node.kind === "file-result" || ev.node.kind === "directory-result") return "compact";
        return "normal";
    }

    function formatBreadcrumbs(breadcrumbs, placement, ev) {
        if (!breadcrumbs || !breadcrumbs.length) return "";
        if (placement === "group-child") return "";
        if (placement === "group") return "";
        if (placement === "nested-group") return "";
        var label = ev && ev.node ? ev.node.label : "";
        return breadcrumbs.concat([label]).join(" > ");
    }

    function toDebug(ctx) {
        if (!ctx) return {};
        return {
            placement: ctx.placement,
            parentShown: ctx.parentShown,
            showBreadcrumbs: ctx.showBreadcrumbs,
            showBackendBadge: ctx.showBackendBadge,
            showActionHint: ctx.showActionHint,
            density: ctx.density,
            breadcrumbText: ctx.breadcrumbText
        };
    }
}
