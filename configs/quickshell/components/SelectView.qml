import QtQuick
import QtQuick.Controls
import QtQml
import qs.utils.types

Item {
    id: root

    property string currentView: ""
    readonly property Item currentItem: stack.currentItem

    implicitWidth: currentItem ? currentItem.implicitWidth : 0
    implicitHeight: currentItem ? currentItem.implicitHeight : 0

    default property alias entries: views.entries
    property var initProps

    SimpleMap {
        id: views
    }

    property var _selectedValue: currentView ? views.get(currentView) : undefined

    on_SelectedValueChanged: {
        syncCurrentView();
    }

    StackView {
        id: stack
        anchors.fill: parent
        implicitWidth: currentItem ? currentItem.implicitWidth : 0
        implicitHeight: currentItem ? currentItem.implicitHeight : 0
    }

    function syncCurrentView() {
        const value = _selectedValue;
        const props = initProps;
        initProps = undefined;

        if (!value) {
            stack.clear(StackView.Immediate);
            return;
        }

        if (stack.depth > 0) {
            if (value instanceof Component && props !== undefined) {
                stack.replace(value, props, StackView.Immediate);
            } else {
                stack.replace(value, StackView.Immediate);
            }
        } else if (value instanceof Component && props !== undefined) {
            stack.push(value, props, StackView.Immediate);
        } else {
            stack.push(value, StackView.Immediate);
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
