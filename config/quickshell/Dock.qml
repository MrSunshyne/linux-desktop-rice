// macOS-style dock on the bottom, left or right edge of the main screen
// (Settings.dockPosition). Apps button (launcher) | pinned apps | running apps
// that aren't pinned.
//
// Geometry is written along the dock's own axis: "main" runs along the dock
// (x at the bottom, y on the sides), "cross" points from the screen edge inward.
//
// Magnification: icons near the pointer grow (Settings.dockMagnification) and
// push their neighbours apart; sizes come from the resting layout so the effect
// doesn't feed back on itself.
// Drag: reorder pinned apps, drop a running app among them to keep it, or pull
// a kept app away from the dock to remove it.
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.ui

Scope {
    id: root

    readonly property string edge: Settings.dockPosition === "left" || Settings.dockPosition === "right" ? Settings.dockPosition : "bottom"
    readonly property bool vertical: edge !== "bottom"

    // ---- Apps and their windows ------------------------------------------------
    readonly property var toplevels: ToplevelManager.toplevels.values

    function entryFor(id) { return DesktopEntries.byId(id) ?? DesktopEntries.heuristicLookup(id); }
    // Window app id -> desktop entry id (e.g. "spotify" -> "com.spotify.Client").
    function keyFor(appId) { return entryFor(appId)?.id ?? appId; }

    readonly property var groups: {
        const g = {};
        for (const t of toplevels) {
            if (!t.appId) continue;
            const k = keyFor(t.appId);
            if (!g[k]) g[k] = [];
            g[k].push(t);
        }
        return g;
    }
    function windowsFor(id) { return groups[id] ?? []; }

    // ---- Drag state (main/cross coordinates) -----------------------------------
    property string dragId: ""
    property bool dragFromPinned: false
    property real dragMain: 0
    property real dragCross: 0         // distance pulled away from the screen edge, >= 0
    property real dragStartCross: 0
    property real grabMain: 0
    property real frozenStart: 0       // layout start at drag begin, so drop slots don't shift
    property bool dragRemoving: false
    property var previewPinned: null   // pinned order while dragging

    readonly property var pinnedOrder: previewPinned ?? Settings.dockPinned
    readonly property var pinnedIds: pinnedOrder.filter(id => DesktopEntries.byId(id) || groups[id])  // skip uninstalled
    readonly property var otherIds: Object.keys(groups).filter(k => !pinnedOrder.includes(k))

    // Slots in display order. The dragged app keeps a zero-size "ghost" slot
    // while it's being removed, so its item (and the drag) survive.
    readonly property var slots: {
        const s = [{ id: "__apps", kind: "apps" }];
        for (const id of pinnedIds) s.push({ id, kind: "app" });
        if (otherIds.length) s.push({ id: "__sep", kind: "sep" });
        for (const id of otherIds) s.push({ id, kind: "app" });
        if (dragId !== "" && !s.some(x => x.id === dragId)) s.push({ id: dragId, kind: "ghost" });
        return s;
    }

    // Stable model: items move instead of being recreated, so animations and
    // an in-progress drag aren't interrupted.
    ListModel { id: slotModel }
    function sync() {
        for (let i = 0; i < slots.length; i++) {
            const want = slots[i];
            let j = -1;
            for (let k = i; k < slotModel.count; k++) if (slotModel.get(k).sid === want.id) { j = k; break; }
            if (j === -1) slotModel.insert(i, { sid: want.id, kind: want.kind });
            else {
                if (j !== i) slotModel.move(j, i, 1);
                if (slotModel.get(i).kind !== want.kind) slotModel.setProperty(i, "kind", want.kind);
            }
        }
        if (slotModel.count > slots.length) slotModel.remove(slots.length, slotModel.count - slots.length);
    }
    onSlotsChanged: sync()
    Component.onCompleted: sync()

    // ---- Geometry -----------------------------------------------------------------
    readonly property int size: Settings.dockIconSize
    readonly property real maxMag: Math.max(1, Settings.dockMagnification)
    readonly property int spacing: 8
    readonly property int gap: 8          // to the screen edge
    readonly property int pad: 8          // inside the dock
    readonly property int thickness: size + 10 + pad * 2    // dock body across its axis

    function slotLength(kind) { return kind === "sep" ? 9 : kind === "ghost" ? 0 : size; }
    readonly property var lengths: slots.map(s => slotLength(s.kind))
    // Start of each slot along the dock in the resting layout, from the first slot.
    readonly property var bases: {
        let m = 0;
        const out = [];
        for (const l of lengths) { out.push(m); if (l > 0) m += l + spacing; }
        return out;
    }
    readonly property real contentLength: {
        let m = 0, n = 0;
        for (const l of lengths) if (l > 0) { m += l; n++; }
        return m + spacing * Math.max(0, n - 1);
    }

    // Magnification: pointer position along the dock and a 0..1 ramp for enter/leave.
    // Bound (not set from a handler): HoverHandler.point changes don't emit pointChanged.
    property var hover: null
    readonly property real hoverMain: !hover ? -1 : vertical ? hover.point.position.y : hover.point.position.x
    readonly property bool hovering: hover?.hovered ?? false
    property real magAmount: hovering && dragId === "" && maxMag > 1.001 ? 1 : 0
    Behavior on magAmount { NumberAnimation { duration: Theme.dur(160); easing.type: Easing.OutCubic } }

    property real stageMain: 0             // stage length along the dock
    property real stageCross: 0
    readonly property real start: (stageMain - contentLength) / 2
    readonly property var growth: slots.map((s, i) => {
        if (s.kind !== "app" && s.kind !== "apps") return 0;
        const d = Math.abs(hoverMain - (start + bases[i] + lengths[i] / 2));
        const range = size * 2.6;
        const f = d < range ? (Math.cos(Math.PI * d / range) + 1) / 2 : 0;
        return (maxMag - 1) * size * f * magAmount;
    })
    readonly property real totalGrowth: growth.reduce((a, g) => a + g, 0)
    // Centre of slot i along the dock after neighbours are pushed apart.
    function slotCenter(i) {
        let before = 0;
        for (let j = 0; j < i; j++) before += growth[j] ?? 0;
        return start + (bases[i] ?? 0) + (lengths[i] ?? 0) / 2 + before + (growth[i] ?? 0) / 2 - totalGrowth / 2;
    }

    // Stage coordinates -> along the dock / away from the screen edge.
    function toMain(x, y) { return vertical ? y : x; }
    function toCross(x, y) {
        return edge === "left" ? x : edge === "right" ? stageCross - x : stageCross - y;
    }

    // ---- Drag handling ----------------------------------------------------------------
    function dragBegin(id, x, y, offset) {
        dragFromPinned = Settings.isPinned(id);
        frozenStart = start;
        grabMain = offset;
        dragMain = toMain(x, y);
        dragStartCross = toCross(x, y);
        dragCross = 0;
        previewPinned = Settings.dockPinned.slice();
        dragId = id;
    }
    function dragMove(x, y) {
        dragMain = toMain(x, y);
        dragCross = Math.max(0, toCross(x, y) - dragStartCross);
        const others = Settings.dockPinned.filter(p => p !== dragId && (DesktopEntries.byId(p) || groups[p]));
        // Pulled well away from the dock: a kept app is removed, a running app is just let go.
        const pulledOut = toCross(x, y) > gap + thickness + 48;
        dragRemoving = dragFromPinned && pulledOut;
        if (pulledOut) { previewPinned = others; return; }

        // Drop slot among the pinned apps, measured on the layout at drag start.
        const slotL = size + spacing;
        const firstCenter = frozenStart + slotL + size / 2;     // after the Apps button
        const at = dragMain - grabMain;
        let idx = 0;
        while (idx < others.length && firstCenter + idx * slotL < at) idx++;
        const pastEnd = at > firstCenter + (others.length + 0.5) * slotL;
        if (!dragFromPinned && pastEnd) { previewPinned = others; return; }   // stays unpinned

        const next = others.slice();
        next.splice(idx, 0, dragId);
        previewPinned = next;
    }
    function dragEnd() {
        const result = previewPinned ?? Settings.dockPinned;
        if (JSON.stringify(result) !== JSON.stringify(Settings.dockPinned))
            Settings.dockPinned = result;
        dragId = "";
        dragRemoving = false;
        previewPinned = null;
    }

    // ---- Auto-hide ----------------------------------------------------------------
    property int menusOpen: 0
    readonly property bool shown: !Settings.dockAutohide || hovering || dragId !== "" || menusOpen > 0 || hideDelay.running
    Timer { id: hideDelay; interval: 600 }
    onHoveringChanged: if (!hovering) hideDelay.restart()

    // A fresh window per edge: layer-shell anchors are set when it's created.
    Variants {
        model: Settings.dockEnabled ? [root.edge] : []

        PanelWindow {
            id: win
            required property string modelData   // the edge
            screen: Quickshell.screens[0]

            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "quickshell-dock"
            anchors {
                bottom: modelData === "bottom"
                left: modelData === "left"
                right: modelData === "right"
            }
            // Room around the dock for magnified icons, the launch bounce and drag-out.
            readonly property real mainExtent: root.contentLength + root.size * (root.maxMag - 1) * 3 + root.pad * 2 + 40
            readonly property real crossExtent: root.thickness + root.gap + Math.max(root.size * (root.maxMag - 1) + 28, 96)
            implicitWidth: root.vertical ? crossExtent : mainExtent
            implicitHeight: root.vertical ? mainExtent : crossExtent
            color: "transparent"

            // Windows tile beside the dock unless it auto-hides.
            exclusionMode: ExclusionMode.Normal
            exclusiveZone: Settings.dockAutohide ? 0 : root.thickness + root.gap
            // Only the dock takes input; while hidden, just a thin strip at the screen edge.
            mask: Region { item: root.shown ? body : edgeStrip }

            // 0 = hidden past the screen edge, 1 = shown.
            property real progress: root.shown ? 1 : 0
            Behavior on progress { NumberAnimation { duration: Theme.dur(260); easing.type: Easing.OutCubic } }

            Item {
                id: dockStage
                anchors.fill: parent
                onWidthChanged: root.vertical ? root.stageCross = width : root.stageMain = width
                onHeightChanged: root.vertical ? root.stageMain = height : root.stageCross = height
                Component.onCompleted: {
                    root.stageMain = root.vertical ? height : width;
                    root.stageCross = root.vertical ? width : height;
                    root.hover = dockHover;
                }

                HoverHandler { id: dockHover }

                // Thin strip on the screen edge that reveals an auto-hidden dock.
                Item {
                    id: edgeStrip
                    x: root.edge === "right" ? parent.width - width : 0
                    y: root.vertical ? 0 : parent.height - height
                    width: root.vertical ? 3 : parent.width
                    height: root.vertical ? parent.height : 3
                }

                // Everything below slides past the screen edge together when auto-hidden.
                Item {
                    id: slider
                    anchors.fill: parent
                    opacity: win.progress
                    readonly property real hide: (1 - win.progress) * (root.thickness + root.gap + 4)
                    transform: Translate {
                        x: root.edge === "left" ? -slider.hide : root.edge === "right" ? slider.hide : 0
                        y: root.vertical ? 0 : slider.hide
                    }

                    Rectangle {
                        id: body
                        readonly property real along: root.contentLength + root.totalGrowth + root.pad * 2
                        width: root.vertical ? root.thickness : along
                        height: root.vertical ? along : root.thickness
                        x: root.edge === "left" ? root.gap
                         : root.edge === "right" ? parent.width - width - root.gap
                         : (parent.width - width) / 2
                        y: root.vertical ? (parent.height - height) / 2 : parent.height - height - root.gap
                        radius: Math.min(root.thickness / 2, Theme.radius + 6)
                        color: Theme.panel
                        border.width: 1
                        border.color: Theme.border
                    }

                    Repeater {
                        model: slotModel
                        delegate: Item {
                            id: slot
                            required property int index
                            required property string sid
                            required property string kind
                            readonly property bool isDragged: root.dragId === sid
                            readonly property real grow: root.growth[index] ?? 0
                            readonly property real len: root.lengths[index] ?? 0
                            readonly property real across: root.size + 10

                            // Along the dock: slot centre, or the pointer while dragged.
                            readonly property real center: isDragged ? root.dragMain - root.grabMain : root.slotCenter(index)
                            // Away from the edge: resting inset, plus how far it's pulled while dragged.
                            readonly property real inset: root.gap + root.pad + (isDragged ? root.dragCross : 0)

                            width: root.vertical ? across : len
                            height: root.vertical ? len : across
                            x: root.vertical ? (root.edge === "left" ? inset : dockStage.width - inset - width) : center - width / 2
                            y: root.vertical ? center - height / 2 : dockStage.height - inset - height
                            // Smoothing is for reorders and apps opening/closing only. While
                            // magnifying, positions must change in the same frame as icon sizes
                            // and the dock body, or neighbours lag behind and then jump.
                            readonly property bool smoothMove: root.dragId !== "" || (!root.hovering && root.magAmount === 0)
                            Behavior on x { enabled: !root.vertical && slot.smoothMove; SmoothedAnimation { velocity: -1; duration: Theme.dur(slot.isDragged ? 40 : 110) } }
                            Behavior on y { enabled: root.vertical && slot.smoothMove; SmoothedAnimation { velocity: -1; duration: Theme.dur(slot.isDragged ? 40 : 110) } }
                            z: isDragged ? 10 : 0
                            opacity: isDragged && root.dragRemoving ? 0.45 : 1
                            Behavior on opacity { NumberAnimation { duration: Theme.anim } }

                            // Apps (launcher). Fixed size, scaled on the GPU (resizing
                            // would re-render the glyph on every pointer move).
                            Rectangle {
                                visible: slot.kind === "apps"
                                width: root.size; height: root.size
                                x: root.edge === "left" ? 10 : 0
                                y: 0
                                transformOrigin: root.edge === "left" ? Item.Left : root.edge === "right" ? Item.Right : Item.Bottom
                                scale: 1 + slot.grow / root.size
                                radius: Math.round(width * 0.26)
                                color: appsMouse.containsMouse ? Theme.cardHover : Theme.card
                                border.width: 1
                                border.color: Theme.border
                                SymbolIcon {
                                    anchors.centerIn: parent
                                    icon: "view-app-grid-symbolic"
                                    size: Math.round(parent.width * 0.42)
                                    color: Theme.fg
                                }
                                MouseArea {
                                    id: appsMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Quickshell.execDetached(["qs", "ipc", "call", "launcher", "toggle"])
                                }
                            }

                            // Separator before running apps that aren't pinned
                            Rectangle {
                                visible: slot.kind === "sep"
                                width: root.vertical ? root.size * 0.7 : 1
                                height: root.vertical ? 1 : root.size * 0.7
                                x: root.vertical ? (root.edge === "left" ? 10 : 0) + root.size * 0.15 : (parent.width - width) / 2
                                y: root.vertical ? (parent.height - height) / 2 : root.size * 0.15
                                color: Theme.border
                            }

                            // App (stays alive as a "ghost" while being dragged out)
                            DockItem {
                                visible: slot.kind === "app" || slot.kind === "ghost"
                                edge: root.edge
                                x: root.vertical ? 0 : (slot.width - width) / 2
                                y: root.vertical ? (slot.height - height) / 2 : 0
                                stage: dockStage
                                appId: slot.sid
                                entry: slot.kind === "app" || slot.kind === "ghost" ? root.entryFor(slot.sid) : null
                                windows: root.windowsFor(slot.sid)
                                magnify: 1 + slot.grow / root.size
                                onMenuOpenChanged: open => root.menusOpen += open ? 1 : -1
                                onDragBegan: (x, y, offset) => root.dragBegin(slot.sid, x, y, offset)
                                onDragMoved: (x, y) => root.dragMove(x, y)
                                onDragEnded: root.dragEnd()
                            }

                            // "Remove" hint while a kept app is pulled out
                            Rectangle {
                                visible: slot.isDragged && root.dragRemoving
                                implicitWidth: removeText.implicitWidth + 16; implicitHeight: 22
                                x: root.edge === "left" ? parent.width + 6
                                 : root.edge === "right" ? -width - 6
                                 : (parent.width - width) / 2
                                y: root.vertical ? (parent.height - height) / 2 : -height - 6
                                radius: 11
                                color: Theme.panel
                                border.width: 1
                                border.color: Theme.border
                                Text {
                                    id: removeText
                                    anchors.centerIn: parent
                                    text: "Remove"
                                    color: Theme.fg
                                    font.family: Theme.font
                                    font.pixelSize: Theme.fontSize - 2
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
