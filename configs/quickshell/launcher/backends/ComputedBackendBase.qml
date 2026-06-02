LauncherBackendBase {
    id: root

    function resultNodes(query, context) {
        return [];
    }

    function rootNode(query, context) {
        const children = root.resultNodes(query, context) || [];
        return root.backendRootDto(children);
    }

    function node(options) {
        const opts = options || {};
        return root.nodeDto(Object.assign({
            kind: "computed-result",
            icon: root.helpIcon || "system-search"
        }, opts));
    }

    function action(id, label, payload) {
        return root.actionDto(id, label, payload || {});
    }
}
