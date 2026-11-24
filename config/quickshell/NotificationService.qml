pragma Singleton
// Notification daemon. Keeps a history for the Notifications tab and
// implements Do Not Disturb: while on, only critical notifications pop up
// (everything still lands in history).
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    property bool dnd: false
    readonly property int maxHistory: 100

    // Plain copies, so history survives the notification itself closing.
    property ListModel history: ListModel {}

    property NotificationServer server: NotificationServer {
        keepOnReload: true
        actionsSupported: true
        imageSupported: true
        bodyMarkupSupported: false
        onNotification: n => {
            root.history.insert(0, {
                appName: n.appName || "",
                appIcon: n.appIcon || "",
                summary: n.summary || "",
                body: n.body || "",
                time: Date.now(),
            });
            if (root.history.count > root.maxHistory)
                root.history.remove(root.maxHistory, root.history.count - root.maxHistory);
            n.tracked = !root.dnd || n.urgency === NotificationUrgency.Critical;
        }
    }

    function clear() { history.clear(); }
    function remove(index) { history.remove(index); }

    // "now", "5 min", "2 h", "3 d"
    function ago(time, now) {
        const s = Math.max(0, (now - time) / 1000);
        if (s < 60) return "now";
        if (s < 3600) return Math.floor(s / 60) + " min";
        if (s < 86400) return Math.floor(s / 3600) + " h";
        return Math.floor(s / 86400) + " d";
    }

    // appIcon may be a path, a URL or a theme icon name.
    function iconSource(icon) {
        if (!icon) return "";
        if (icon.startsWith("/") || icon.includes("://")) return icon;
        return Quickshell.iconPath(icon, true);
    }
}
