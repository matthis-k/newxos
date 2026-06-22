import QtQml
import "../" as Launcher
import "../logic/"
import "presentation/"

QtObject {
    Component.onCompleted: {
        Launcher.PolicyRegistry.registerPresentation("preset-presentation", function(ev, ctx) {
            var node = ev.node;
            var presentationId = (node.behavior && node.behavior.presentation) || node.presentation || "";
            var preset = PresentationPresets.presetForKind(presentationId || node.kind);
            if (!preset) return null;
            return PresentationPolicy.decideByPreset(ev, ctx, preset);
        });

        Launcher.PolicyRegistry.registerPresentation("switch-presentation", function(ev, ctx) {
            if (!ev.node.switchActions) return null;
            return PresentationPolicy.decideSwitchPresentation(ev, ctx);
        });

        Launcher.PolicyRegistry.registerPresentation("default-presentation", function(ev, ctx) {
            return { mode: "normal", showParent: true, children: ev.children || [] };
        });
    }
}
