pragma Singleton
import Quickshell

Singleton {
    function findContainingQsWindow(item) {
        var cur = item;
        while (cur) {
            // attached object is QsWindow (named in C++ as QsWindow)
            if (cur.QsWindow && cur.QsWindow.window)
                return cur.QsWindow.window; // climb visual parent (parentItem) or QObject parent (parent)
            cur = cur.parent || cur.parentItem;
        }
        return null;
    }
    function getScreen(item) {
        var cur = item;
        while (true) {
            if (cur.screen) {
                return cur.screen;
            } else if (cur.parent) {
                cur = cur.parent;
            } else {
                return cur;
            }
        }
    }
}
