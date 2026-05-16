pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    property alias toastsEnabled: state.toastsEnabled
    readonly property bool doNotDisturbEnabled: !toastsEnabled
    readonly property var notifications: server.trackedNotifications.values || []
    readonly property int count: notifications.length
    readonly property int criticalCount: notifications.filter(notification => notification.urgency === NotificationUrgency.Critical).length
    readonly property bool hasCritical: criticalCount > 0
    readonly property string badgeText: count > 99 ? "99+" : (count > 0 ? `${count}` : "")

    function dismiss(notification) {
        notification?.dismiss();
    }

    function clearAll() {
        for (const notification of notifications)
            notification.dismiss();
    }

    function invokeDefaultAction(notification) {
        if (!notification)
            return;

        if (notification.actions.length > 0) {
            notification.actions[0].invoke();
            return;
        }

        notification.dismiss();
    }

    function urgencyColor(notification) {
        if (!notification)
            return Config.styling.text0;

        if (notification.urgency === NotificationUrgency.Critical)
            return Config.styling.critical;

        if (notification.urgency === NotificationUrgency.Low)
            return Config.styling.text2;

        return Config.styling.text0;
    }

    function renderBody(body) {
        let text = (body || "").trim();
        if (text === "")
            return "";

        text = text
            .replace(/&/g, "&amp;")
            .replace(/</g, "&lt;")
            .replace(/>/g, "&gt;");

        text = text.replace(/`([^`]+)`/g, "<code>$1</code>");
        text = text.replace(/\*\*([^*]+)\*\*/g, "<b>$1</b>");
        text = text.replace(/(^|[^*])\*([^*]+)\*(?!\*)/g, "$1<i>$2</i>");
        text = text.replace(/\[([^\]]+)\]\((https?:\/\/[^\s)]+)\)/g, '<a href="$2">$1</a>');

        const lines = text.split(/\n/);
        let inList = false;
        const rendered = [];

        for (const line of lines) {
            const bulletMatch = line.match(/^\s*[-*]\s+(.*)$/);
            if (bulletMatch) {
                if (!inList) {
                    rendered.push("<ul>");
                    inList = true;
                }
                rendered.push(`<li>${bulletMatch[1]}</li>`);
                continue;
            }

            if (inList) {
                rendered.push("</ul>");
                inList = false;
            }

            rendered.push(line);
        }

        if (inList)
            rendered.push("</ul>");

        return rendered.join("<br/>");
    }

    PersistentProperties {
        id: state
        property bool toastsEnabled: true
        reloadableId: "notificationCenterState"
    }

    NotificationServer {
        id: server
        actionsSupported: true
        actionIconsSupported: true
        bodySupported: true
        bodyHyperlinksSupported: true
        bodyMarkupSupported: true
        imageSupported: true
        bodyImagesSupported: true
        persistenceSupported: true
        keepOnReload: true

        onNotification: function(notification) {
            notification.tracked = true;
        }
    }
}
