pragma Singleton
import Quickshell

Singleton {
    id: root

    property var _bindings: ({})

    function register(nodeId, delegateProp, sourceObj, sourceProp) {
        if (!nodeId || !delegateProp || !sourceObj || !sourceProp) {
            console.warn("BindingRegistry.register: invalid args", nodeId, delegateProp);
            return;
        }
        if (!_bindings[nodeId])
            _bindings[nodeId] = {};
        _bindings[nodeId][delegateProp] = {
            obj: sourceObj,
            prop: sourceProp
        };
    }

    function registerMany(nodeId, spec) {
        if (!nodeId || !spec)
            return;
        for (var prop in spec) {
            var s = spec[prop];
            if (s && s.obj && s.prop)
                root.register(nodeId, prop, s.obj, s.prop);
        }
    }

    function unregister(nodeId) {
        delete _bindings[nodeId];
    }

    function unregisterField(nodeId, fieldName) {
        if (_bindings[nodeId])
            delete _bindings[nodeId][fieldName];
    }

    function applyBindings(delegate, nodeId) {
        if (!delegate || !nodeId || !_bindings[nodeId])
            return;

        var nodeBindings = _bindings[nodeId];
        for (var prop in nodeBindings) {
            if (!(prop in delegate))
                continue;
            var b = nodeBindings[prop];
            delegate[prop] = Qt.binding((function (obj, p) {
                    return function () {
                        return obj[p];
                    };
                })(b.obj, b.prop));
        }
    }

    function has(nodeId, fieldName) {
        return !!(nodeId && fieldName && _bindings[nodeId] && _bindings[nodeId][fieldName] !== undefined);
    }

    function list() {
        return Object.keys(_bindings);
    }
}
