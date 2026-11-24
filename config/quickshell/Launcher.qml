// App launcher. Toggle with Super+Space (hyprland.lua runs
// `qs ipc call launcher toggle`).
// Type to search; Up/Down or Ctrl+N/P (Ctrl+J/K) to move; Enter to launch;
// Esc or a click outside to close.
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets

Scope {
    id: root
    property bool opened: false

    function show() {
        search.text = "";
        list.currentIndex = 0;
        opened = true;
    }
    function hide() { opened = false; }

    IpcHandler {
        target: "launcher"
        function toggle(): void { root.opened ? root.hide() : root.show(); }
        function open(): void { root.show(); }
        function close(): void { root.hide(); }
    }

    // Ranks apps against the query. Higher score = better match.
    function score(app, q) {
        const name = app.name.toLowerCase();
        if (name === q) return 1000;
        if (name.startsWith(q)) return 800 - name.length;
        const words = name.split(/[\s\-_.]+/);
        if (words.some(w => w.startsWith(q))) return 600 - name.length;
        if (words.map(w => w[0] ?? "").join("").startsWith(q)) return 500;   // "vsc" -> Visual Studio Code
        if (name.includes(q)) return 400 - name.indexOf(q);
        if (app.genericName.toLowerCase().includes(q)) return 250;
        if (app.keywords.some(k => k.toLowerCase().startsWith(q))) return 200;
        if (app.comment.toLowerCase().includes(q)) return 100;
        let i = 0;                                                         // fuzzy: letters in order
        for (const c of name) if (c === q[i]) i++;
        return i === q.length ? 50 : -1;
    }

    readonly property var results: {
        const q = search.text.trim().toLowerCase();
        const apps = DesktopEntries.applications.values;
        if (q === "")
            return [...apps].sort((a, b) => a.name.localeCompare(b.name));
        return apps
            .map(app => ({ app, s: score(app, q) }))
            .filter(r => r.s >= 0)
            .sort((a, b) => b.s - a.s || a.app.name.localeCompare(b.app.name))
            .map(r => r.app);
    }

    function launch(app) {
        if (!app) return;
        hide();
        if (app.runInTerminal)
            Quickshell.execDetached({ command: ["kitty", "-e", ...app.command], workingDirectory: app.workingDirectory });
        else
            app.execute();
    }

    PanelWindow {
        id: win
        // 0 = hidden (raised and faded), 1 = in place. Same easing as the
        // Control Center: soft landing on open, quicker exit.
        property real progress: 0
        NumberAnimation {
            id: dropIn
            target: win; property: "progress"; to: 1
            duration: Theme.dur(360); easing.type: Easing.OutQuint
        }
        NumberAnimation {
            id: liftOut
            target: win; property: "progress"; to: 0
            duration: Theme.dur(200); easing.type: Easing.InCubic
        }
        Connections {
            target: root
            function onOpenedChanged() {
                if (root.opened) { liftOut.stop(); dropIn.start(); search.forceActiveFocus(); }
                else { dropIn.stop(); liftOut.start(); }
            }
        }

        visible: root.opened || progress > 0
        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell-launcher"
        // Release the keyboard as soon as it starts closing.
        WlrLayershell.keyboardFocus: root.opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore
        anchors { top: true; bottom: true; left: true; right: true }
        color: Qt.alpha(Theme.backdrop, Theme.backdrop.a * progress)
        onVisibleChanged: if (visible) search.forceActiveFocus()

        // Click outside the box closes the launcher.
        MouseArea {
            anchors.fill: parent
            onClicked: root.hide()
        }

        Rectangle {
            id: box
            width: 640
            height: 480
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height * 0.2
            radius: Theme.radius
            opacity: win.progress
            transform: Translate { y: (1 - win.progress) * -40 }
            color: Theme.panel
            border.width: 1
            border.color: Theme.border

            MouseArea { anchors.fill: parent }   // swallow clicks inside the box

            TextInput {
                id: search
                anchors { top: parent.top; left: parent.left; right: parent.right; margins: 18 }
                height: 32
                verticalAlignment: TextInput.AlignVCenter
                color: Theme.fg
                selectionColor: Theme.accent
                font.family: Theme.font
                font.pixelSize: Theme.fontSize + 5
                clip: true
                onTextChanged: list.currentIndex = 0

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: search.text === ""
                    text: "Search apps…"
                    color: Theme.muted
                    font: search.font
                }

                Keys.onPressed: event => {
                    const ctrl = event.modifiers & Qt.ControlModifier;
                    if (event.key === Qt.Key_Escape) {
                        root.hide();
                    } else if (event.key === Qt.Key_Down || (ctrl && (event.key === Qt.Key_N || event.key === Qt.Key_J))) {
                        list.incrementCurrentIndex();
                    } else if (event.key === Qt.Key_Up || (ctrl && (event.key === Qt.Key_P || event.key === Qt.Key_K))) {
                        list.decrementCurrentIndex();
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        root.launch(root.results[list.currentIndex]);
                    } else {
                        return;
                    }
                    event.accepted = true;
                }
            }

            Rectangle {
                id: divider
                anchors { top: search.bottom; left: parent.left; right: parent.right; topMargin: 12 }
                height: 1
                color: Theme.border
                opacity: 0.4
            }

            ListView {
                id: list
                anchors { top: divider.bottom; bottom: parent.bottom; left: parent.left; right: parent.right; margins: 8 }
                clip: true
                model: root.results
                highlightMoveDuration: 0
                keyNavigationWraps: true
                boundsBehavior: Flickable.StopAtBounds

                delegate: Rectangle {
                    required property var modelData
                    required property int index
                    width: list.width
                    height: 44
                    radius: 8
                    color: ListView.isCurrentItem ? Qt.rgba(1, 1, 1, 0.08) : "transparent"

                    IconImage {
                        id: icon
                        anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                        implicitSize: 28
                        source: Quickshell.iconPath(modelData.icon, "application-x-executable")
                    }
                    Column {
                        anchors { left: icon.right; leftMargin: 12; right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
                        Text {
                            width: parent.width
                            text: modelData.name
                            color: Theme.fg
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize + 1
                            elide: Text.ElideRight
                        }
                        Text {
                            width: parent.width
                            visible: text !== ""
                            text: modelData.genericName || modelData.comment
                            color: Theme.muted
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 1
                            elide: Text.ElideRight
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: list.currentIndex = index
                        onClicked: root.launch(modelData)
                    }
                }
            }
        }
    }
}
