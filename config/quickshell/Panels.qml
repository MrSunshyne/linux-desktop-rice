pragma Singleton
// Open/closed state and active tab of the Control Center.
// Bar widgets call Panels.toggle("audio") etc.; `qs ipc call controlcenter ...`
// goes through ControlCenter.qml to the same functions.
import QtQuick
import Quickshell

Singleton {
    property bool open: false
    property string tab: "home"

    readonly property var tabs: [
        { id: "home",          label: "Home",          icon: "user-home-symbolic" },
        { id: "audio",         label: "Audio",         icon: "audio-speakers-symbolic" },
        { id: "network",       label: "Network",       icon: "network-wireless-symbolic" },
        { id: "bluetooth",     label: "Bluetooth",     icon: "bluetooth-active-symbolic" },
        { id: "media",         label: "Media",         icon: "multimedia-player-symbolic" },
        { id: "calendar",      label: "Calendar",      icon: "x-office-calendar-symbolic" },
        { id: "notifications", label: "Notifications", icon: "preferences-system-notifications-symbolic" },
        { id: "settings",      label: "Settings",      icon: "preferences-system-symbolic" },
    ]

    function isOpen(t) { return open && tab === t; }

    // Same tab again closes; another tab switches without closing.
    // `x` (optional): screen x of the bar item that opened it; the panel
    // grows out of that point. Without it, it grows from the top-right corner.
    property real sourceX: -1
    function toggle(t, x) {
        t = t || "home";
        if (isOpen(t)) open = false;
        else { tab = t; sourceX = x ?? -1; open = true; picker = ""; }
    }
    function show(t, x) {
        if (t) tab = t;
        if (!open) sourceX = x ?? -1;
        open = true;
        picker = "";
    }
    function close() { open = false; }

    // Small picker under a bar icon (BarPicker.qml): "wifi", "bluetooth" or "".
    // `x` is the icon's horizontal centre in screen coordinates.
    property string picker: ""
    property real pickerX: 0
    function togglePicker(kind, x) {
        if (picker === kind) { picker = ""; return; }
        if (x !== undefined) pickerX = x;
        open = false;
        picker = kind;
    }
    function closePicker() { picker = ""; }
}
