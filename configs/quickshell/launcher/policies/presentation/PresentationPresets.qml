pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property QtObject discoverableCommandGroupPreset: QtObject {
        readonly property string id: "discoverable-command-group"
        readonly property bool showParent: true
        readonly property bool filterable: true
        readonly property var flattenPolicy: ({
            priority: 120,
            groupDisplay: {
                parentWinsMargin: 0.08, childWinsMargin: 0.03, childDominatesMargin: 0.18,
                maxFlattenedChildren: 8, minChildScore: 0.2,
                showGroupHeaderInFilteredMode: true,
                committedTokenPrefersGroup: true, committedTokenMinParentScore: 0.15,
                showAllChildrenOnParentMatch: true, flattenAllChildrenOnParentMatch: true,
                parentMatchMinScore: 0.1
            }
        })
        readonly property var displayPolicy: ({ discoverable: true, breadcrumbMode: "when-parent-dominates" })
    }
    readonly property QtObject namespaceGroupPreset: QtObject {
        readonly property string id: "namespace-group"
        readonly property bool showParent: false
        readonly property var flattenPolicy: ({ groupDisplay: { maxFlattenedChildren: 6, minChildScore: 0.2, parentWinsMargin: 0.05 } })
        readonly property var displayPolicy: ({ breadcrumbMode: "always" })
    }
    readonly property QtObject appEntryPreset: QtObject {
        readonly property string id: "app-entry"
        readonly property bool filterable: true
        readonly property bool showParent: true
        readonly property var flattenPolicy: ({ groupDisplay: { parentWinsMargin: 0.15, childDominatesMargin: 0.25, maxFlattenedChildren: 3, minChildScore: 0.3, showAllChildrenOnParentMatch: false, parentMatchMinScore: 0.3 } })
        readonly property var displayPolicy: ({ breadcrumbMode: "when-parent-dominates" })
    }
    readonly property QtObject safeActionGroupPreset: QtObject {
        readonly property string id: "safe-action-group"
        readonly property bool filterable: true
        readonly property var flattenPolicy: ({ groupDisplay: { parentWinsMargin: 0.08, childDominatesMargin: 0.18, maxFlattenedChildren: 5, minChildScore: 0.25, showAllChildrenOnParentMatch: true, parentMatchMinScore: 0.15 } })
        readonly property var displayPolicy: ({ breadcrumbMode: "default" })
    }
    readonly property QtObject commandGroupPreset: QtObject {
        readonly property string id: "command-group"
        readonly property bool filterable: true
        readonly property var flattenPolicy: ({ groupDisplay: { parentWinsMargin: 0.1, childDominatesMargin: 0.2, maxFlattenedChildren: 6, minChildScore: 0.25, showAllChildrenOnParentMatch: true, parentMatchMinScore: 0.15 } })
    }
    readonly property QtObject dangerousCommandGroupPreset: QtObject {
        readonly property string id: "dangerous-command-group"
        readonly property bool filterable: true
        readonly property var flattenPolicy: ({ groupDisplay: { parentWinsMargin: 0.15, childWinsMargin: 0.05, childDominatesMargin: 0.25, maxFlattenedChildren: 4, minChildScore: 0.3, showAllChildrenOnParentMatch: false, parentMatchMinScore: 0.3, committedTokenPrefersGroup: true, committedTokenMinParentScore: 0.3 } })
        readonly property var displayPolicy: ({ breadcrumbMode: "always" })
    }
    readonly property QtObject switchControlPreset: QtObject {
        readonly property string id: "switch-control"
        readonly property var flattenPolicy: ({ modeHint: "group-mode-inhibit" })
    }
    readonly property QtObject sliderControlPreset: QtObject {
        readonly property string id: "slider-control"
        readonly property var flattenPolicy: ({ modeHint: "group-mode-inhibit" })
    }
    readonly property QtObject fileResultPreset: QtObject {
        readonly property string id: "file-result"
        readonly property var flattenPolicy: ({ modeHint: "group-mode-inhibit" })
    }
    readonly property QtObject directoryResultPreset: QtObject {
        readonly property string id: "directory-result"
        readonly property var flattenPolicy: ({ groupDisplay: { maxFlattenedChildren: 20, minChildScore: 0.1 } })
    }
    readonly property QtObject pathExplorerResultPreset: QtObject {
        readonly property string id: "path-explorer-result"
        readonly property var flattenPolicy: ({ groupDisplay: { maxFlattenedChildren: 24, minChildScore: 0.1 } })
    }
    readonly property QtObject computedLeafPreset: QtObject {
        readonly property string id: "computed-leaf"
        readonly property var flattenPolicy: ({ modeHint: "group-mode-inhibit" })
    }

    function presetForKind(kind) {
        switch (kind) {
        case "discoverable-command-group": return root.discoverableCommandGroupPreset;
        case "namespace-group": return root.namespaceGroupPreset;
        case "app-entry": return root.appEntryPreset;
        case "safe-action-group": return root.safeActionGroupPreset;
        case "command-group": return root.commandGroupPreset;
        case "dangerous-command-group": return root.dangerousCommandGroupPreset;
        case "switch-control": return root.switchControlPreset;
        case "slider-control": return root.sliderControlPreset;
        case "file-result": return root.fileResultPreset;
        case "directory-result": return root.directoryResultPreset;
        case "path-explorer-result": return root.pathExplorerResultPreset;
        case "computed-leaf": return root.computedLeafPreset;
        default: return null;
        }
    }
}
