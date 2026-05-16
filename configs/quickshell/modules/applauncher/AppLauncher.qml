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
    id: root
    currentView: "appsearch"

    property var _desktopEntry

    SimpleMap.Entry {
        key: "appsearch"
        value: AppSearch {
            view: view
            closeHandler: closeLauncher
        }
    }

    function openDetails(desktopEntry: DesktopEntry) {
        root.initProps = {
            view: view,
            desktopEntry: desktopEntry
        };
        root.insert("details", detailsComponent);
        root.currentView = "details";
    }

    Component {
        id: detailsComponent
        AppDetails {}
    }

    function closeDetails() {
        root.currentView = "appsearch";
        root.currentItem.searchTerm = "";
        root.currentItem.onEnter();
        root.remove("details");
        _desktopEntry = undefined;
    }

    function closeLauncher() {
        ShellState.getScreenByName(screen.name).appLauncher.close();
    }
}
