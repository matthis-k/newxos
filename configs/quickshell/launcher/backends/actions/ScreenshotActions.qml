import QtQml
import qs.services

QtObject {
    function shot(id, aliases, title, subtitle, icon, color, command) { return { id: id, aliases: aliases, title: title, subtitle: subtitle, icon: icon, iconColor: color, action: { service: "desktop", op: "exec", command: command } }; }
    function roots(context) { return [{ id: "screenshot", aliases: ["ss", "screenshot"], title: qsTr("Screenshot"), icon: "camera-photo-symbolic", iconColor: Config.styling.secondaryAccent, template: "flat-action-group", behavior: { filterable: true }, children: [
        shot("area", ["area", "region"], qsTr("Area"), qsTr("Capture a selected region"), "image-region-symbolic", Config.styling.primaryAccent, ["grimblast", "--notify", "copysave", "area"]),
        shot("window", ["window"], qsTr("Window"), qsTr("Capture the active window"), "window-symbolic", Config.styling.secondaryAccent, ["grimblast", "--notify", "copysave", "active"]),
        shot("screen", ["screen", "full", "display"], qsTr("Screen"), qsTr("Capture all displays"), "video-display-symbolic", Config.styling.info, ["grimblast", "--notify", "copysave", "output"]),
        shot("read", ["read", "ocr", "text"], qsTr("Read"), qsTr("Extract text from clipboard image (OCR)"), "text-editor-symbolic", Config.styling.good, ["sh", "-c", "read-image --clipboard | wl-copy && notify-send 'Screen OCR' 'Copied text to clipboard'"]),
        shot("annotate", ["annotate", "edit", "satty"], qsTr("Annotate"), qsTr("Annotate clipboard image with satty"), "image-x-generic-symbolic", Config.styling.urgent, ["annotate", "--clipboard"])
    ] }]; }
}
