import QtQuick
import QtQuick.Controls
import QtQml
import qs.utils.types

StackView {
    id: root

    property string currentView: ""

    implicitWidth: currentItem ? currentItem.implicitWidth : 0
    implicitHeight: currentItem ? currentItem.implicitHeight : 0
    clip: true

    default property alias entries: views.entries
    property var initProps

    SimpleMap {
        id: views
    }

    property var _selectedValue: currentView ? views.get(currentView) : undefined

    on_SelectedValueChanged: {
        syncCurrentView();
    }

    function syncCurrentView() {
        const value = _selectedValue;
        const props = initProps;
        initProps = undefined;

        if (!value) {
            root.clear(StackView.Immediate);
            return;
        }

        if (root.depth > 0) {
            if (value instanceof Component && props !== undefined) {
                root.replace(value, props);
            } else {
                root.replace(value);
            }
        } else if (value instanceof Component && props !== undefined) {
            root.push(value, props, StackView.Immediate);
        } else {
            root.push(value, StackView.Immediate);
        }
    }

    function get(key, defaultValue) {
        return views.get(key, defaultValue);
    }
    function has(key) {
        return views.has(key);
    }
    function keys() {
        return views.keys();
    }
    function values() {
        return views.values();
    }

    function getEntry(key) {
        return views.getEntry(key);
    }
    function insert(key, value) {
        return views.insert(key, value);
    }
    function remove(key) {
        const removed = views.remove(key);
        if (removed && currentView === key)
            currentView = "";
        return removed;
    }
    function clear() {
        currentView = "";
        return views.clear();
    }
}
