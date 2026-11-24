// One app in the dock. Positioned and sized by Dock.qml.
// Left click: open it, or focus its window (again: next window of that app).
// Middle click: new window. Right click: menu. Drag: reorder / keep / remove
// (the dock does the bookkeeping; this item reports pointer positions).
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs

Item {
    id: root
    property var entry: null        // DesktopEntry, or null for apps without one
    property string appId           // desktop id (pinned) or window app id
    property var windows: []        // Toplevels of this app
    property int size: Settings.dockIconSize
    property real magnify: 1        // set by the dock from the pointer position
    property Item stage             // fixed item the dock measures positions in
    property string edge: "bottom"  // screen edge the dock is on: bottom | left | right
    readonly property bool vertical: edge !== "bottom"

    signal menuOpenChanged(bool open)
    signal dragBegan(real x, real y, real grabMain)   // grabMain: pointer offset from centre along the dock
    signal dragMoved(real x, real y)
    signal dragEnded()

    readonly property bool running: windows.length > 0
    readonly property bool focused: windows.some(w => w.activated)
    readonly property bool pinned: Settings.isPinned(appId)
    readonly property string name: entry?.name || appId
    readonly property string iconSource: {
        const i = entry?.icon || appId;
        return i.startsWith("/") ? "file://" + i : Quickshell.iconPath(i, "application-x-executable");
    }
    // Without magnification, a small hover lift instead.
    readonly property real visualScale: Settings.dockMagnification > 1.001 ? magnify
        : (mouse.containsMouse && !mouse.dragged ? 1.1 : 1)
    readonly property real iconSize: size * visualScale

    // 10 px on the screen-edge side for the running dots.
    implicitWidth: vertical ? size + 10 : size
    implicitHeight: vertical ? size : size + 10

    function launch() {
        if (!entry) return;
        bounce.restart();
        if (entry.runInTerminal)
            Quickshell.execDetached({ command: ["kitty", "-e", ...entry.command], workingDirectory: entry.workingDirectory });
        else
            entry.execute();
    }
    function activate() {
        if (!running) { launch(); return; }
        const i = windows.findIndex(w => w.activated);
        windows[(i + 1) % windows.length].activate();
    }

    // Launch bounce
    property real lift: 0
    SequentialAnimation {
        id: bounce
        loops: 2
        NumberAnimation { target: root; property: "lift"; to: -14; duration: Theme.dur(170); easing.type: Easing.OutQuad }
        NumberAnimation { target: root; property: "lift"; to: 0; duration: Theme.dur(170); easing.type: Easing.InQuad }
    }

    // Icon grows away from the screen edge, centred on its slot. It's loaded
    // once at the largest size it can reach and scaled on the GPU: changing its
    // real size would make IconImage re-request the image on every pointer
    // move, which shows up as flicker.
    readonly property real maxScale: Math.max(1.1, Settings.dockMagnification)
    readonly property int big: Math.ceil(size * maxScale)
    IconImage {
        id: icon
        width: root.big
        height: root.big
        implicitSize: root.big
        // Edge-side of the icon stays put; `lift` (negative) moves it away from the edge.
        x: root.edge === "left" ? 10 - root.lift
         : root.edge === "right" ? root.size - root.big + root.lift
         : (root.width - root.big) / 2
        y: root.vertical ? (root.height - root.big) / 2 : root.size - root.big + root.lift
        source: root.iconSource
        asynchronous: true
        smooth: true
        mipmap: true                   // clean downscaling at rest size
        transformOrigin: root.edge === "left" ? Item.Left : root.edge === "right" ? Item.Right : Item.Bottom
        scale: root.visualScale / root.maxScale
        Behavior on scale { enabled: Settings.dockMagnification <= 1.001; NumberAnimation { duration: Theme.dur(160); easing.type: Easing.OutCubic } }
    }

    // Running indicator on the screen-edge side: one dot per window (max 3),
    // stretched along the dock when focused.
    Grid {
        columns: root.vertical ? 1 : 3
        spacing: 3
        x: root.edge === "left" ? 1 : root.edge === "right" ? root.width - implicitWidth - 1 : (root.width - implicitWidth) / 2
        y: root.vertical ? (root.height - implicitHeight) / 2 : root.height - implicitHeight - 1
        Repeater {
            model: Math.min(root.windows.length, 3)
            delegate: Rectangle {
                readonly property int long: root.focused ? 10 : 5
                width: root.vertical ? 5 : long
                height: root.vertical ? long : 5
                radius: 2.5
                color: root.focused ? Theme.accent : Qt.alpha(Theme.fg, 0.75)
                Behavior on width { NumberAnimation { duration: Theme.anim } }
                Behavior on height { NumberAnimation { duration: Theme.anim } }
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: dragged ? Qt.ClosedHandCursor : Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton

        property bool dragged: false
        property point pressAt

        onPressed: event => { pressAt = Qt.point(event.x, event.y); dragged = false; }
        onPositionChanged: event => {
            if (!(event.buttons & Qt.LeftButton)) return;
            const p = mapToItem(root.stage, event.x, event.y);
            if (!dragged && Math.hypot(event.x - pressAt.x, event.y - pressAt.y) > 8) {
                dragged = true;
                const c = root.mapToItem(root.stage, root.width / 2, root.height / 2);
                root.dragBegan(p.x, p.y, root.vertical ? p.y - c.y : p.x - c.x);
            }
            if (dragged) root.dragMoved(p.x, p.y);
        }
        onReleased: if (dragged) root.dragEnded()
        onClicked: event => {
            if (dragged) return;
            if (event.button === Qt.RightButton) menu.visible = true;
            else if (event.button === Qt.MiddleButton) root.launch();
            else root.activate();
        }
    }

    // ---- Name tooltip ------------------------------------------------------
    Timer { id: tipDelay; interval: 350; running: mouse.containsMouse && !menu.visible }
    PopupWindow {
        id: tip
        visible: mouse.containsMouse && !mouse.dragged && !menu.visible && !tipDelay.running
        anchor.item: root
        // Beside the largest the icon can get, on the side away from the screen
        // edge. Fixed, so the popup isn't moved every frame.
        anchor.rect.x: root.edge === "left" ? 10 + root.big + 8
            : root.edge === "right" ? root.size - root.big - implicitWidth - 8
            : (root.width - implicitWidth) / 2
        anchor.rect.y: root.vertical ? (root.height - implicitHeight) / 2 : root.size - root.big - implicitHeight - 8
        implicitWidth: tipText.implicitWidth + 20
        implicitHeight: 28
        color: "transparent"
        Rectangle {
            anchors.fill: parent
            radius: Math.min(height / 2, Theme.radiusSmall)
            color: Theme.panel
            border.width: 1
            border.color: Theme.border
            Text {
                id: tipText
                anchors.centerIn: parent
                text: root.name
                color: Theme.fg
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 1
            }
        }
    }

    // ---- Right-click menu ----------------------------------------------------
    PopupWindow {
        id: menu
        visible: false
        grabFocus: true                 // closes on a click elsewhere
        onVisibleChanged: root.menuOpenChanged(visible)
        anchor.item: root
        anchor.rect.x: root.edge === "left" ? root.width + 16
            : root.edge === "right" ? -implicitWidth - 16
            : (root.width - implicitWidth) / 2
        anchor.rect.y: root.vertical ? (root.height - implicitHeight) / 2 : -implicitHeight - 16
        implicitWidth: 240
        implicitHeight: menuColumn.implicitHeight + 12
        color: "transparent"

        component MenuRow: Rectangle {
            id: row
            property string label
            property bool bold: false
            property bool danger: false
            signal triggered()
            Layout.fillWidth: true
            implicitHeight: 30
            radius: Theme.radiusSmall
            color: rowMouse.containsMouse ? (danger ? Qt.alpha(Theme.red, 0.18) : Theme.cardHover) : "transparent"
            Text {
                anchors { left: parent.left; right: parent.right; leftMargin: 10; rightMargin: 10; verticalCenter: parent.verticalCenter }
                text: row.label
                elide: Text.ElideRight
                color: row.danger && rowMouse.containsMouse ? Theme.red : Theme.fg
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 1
                font.weight: row.bold ? Font.DemiBold : Font.Normal
            }
            MouseArea {
                id: rowMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: { menu.visible = false; row.triggered(); }
            }
        }
        component Divider: Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.border }

        Rectangle {
            anchors.fill: parent
            radius: Theme.radiusCard
            color: Theme.panel
            border.width: 1
            border.color: Theme.border

            ColumnLayout {
                id: menuColumn
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 6 }
                spacing: 2

                Text {
                    Layout.fillWidth: true
                    Layout.margins: 6
                    text: root.name
                    elide: Text.ElideRight
                    color: Theme.muted
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 2
                    font.weight: Font.DemiBold
                }
                // Open windows, click to focus
                Repeater {
                    model: root.windows
                    delegate: MenuRow {
                        required property var modelData
                        label: modelData.title || root.name
                        bold: modelData.activated
                        onTriggered: modelData.activate()
                    }
                }
                Divider { visible: root.running }
                MenuRow { visible: root.entry !== null; label: root.running ? "New window" : "Open"; onTriggered: root.launch() }
                MenuRow {
                    visible: root.entry !== null
                    label: root.pinned ? "Remove from dock" : "Keep in dock"
                    onTriggered: Settings.togglePin(root.appId)
                }
                MenuRow {
                    visible: root.running
                    danger: true
                    label: root.windows.length > 1 ? "Quit (close " + root.windows.length + " windows)" : "Quit"
                    onTriggered: root.windows.forEach(w => w.close())
                }
            }
        }
    }
}
