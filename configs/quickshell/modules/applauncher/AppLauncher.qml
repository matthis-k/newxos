import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.components
import qs.services
import qs.utils
import qs.utils.types
import "."

SelectView {
    id: view
    currentView: "appsearch"

    SimpleMap.Entry {
        key: "appsearch"
        value: AppSearch {
            view: view
            closeHandler: closeLauncher
        }
    }

    property var _desktopEntry
    function openDetails(desktopEntry: DesktopEntry) {
        view.initProps = {
            view: view,
            desktopEntry: desktopEntry
        };
        view.insert("details", Qt.createComponent(Qt.resolvedUrl("AppDetails.qml")));
        view.currentView = "details";
    }

    function closeDetails() {
        view.currentView = "appsearch";
        view.currentItem.searchTerm = "";
        view.currentItem.onEnter();
        view.remove("details");
        _desktopEntry = undefined;
    }

    function closeLauncher() {
        ShellState.getScreenByName(screen.name).appLauncher.close();
    }
}
