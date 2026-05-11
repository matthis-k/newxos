import QtQuick

QtObject {
    id: root
    default property list<Entry> entries

    component Entry: QtObject {
        property var key
        property var value
    }
    property Component entryFactory: Component {
        Entry {}
    }
    property bool _reactivityTrigger: false

    function _touch() {
        _reactivityTrigger = !_reactivityTrigger;
    }

    function getEntry(key) {
        return entries.find(e => e && e.key === key) || null;
    }

    function get(key, defaultValue) {
        _reactivityTrigger;
        const e = entries.find(e => e && e.key === key);
        return e ? e.value : defaultValue;
    }

    function has(key) {
        _reactivityTrigger;
        return entries.some(e => e && e.key === key);
    }

    function keys() {
        _reactivityTrigger;
        return entries.filter(e => e).map(e => e.key);
    }

    function values() {
        _reactivityTrigger;
        return entries.filter(e => e).map(e => e.value);
    }

    function insert(key, value) {
        const existing = entries.find(e => e && e.key === key);
        if (existing) {
            existing.value = value;
            _touch();
            return existing;
        }

        const e = entryFactory.createObject(root, {
            key: key,
            value: value
        });
        entries.push(e);
        _touch();
        return e;
    }

    function remove(key) {
        const idx = entries.findIndex(e => e && e.key === key);
        if (idx === -1)
            return false;

        const e = entries[idx];
        entries.splice(idx, 1);
        e.destroy();
        _touch();
        return true;
    }

    function clear() {
        entries.forEach(e => e && e.destroy());
        entries.length = 0;
        _touch();
    }
}
