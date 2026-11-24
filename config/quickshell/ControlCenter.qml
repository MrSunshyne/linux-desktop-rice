// Control Center: one panel under the bar's right end with a tab sidebar.
// Open from the bar, or `qs ipc call controlcenter toggle <tab>`
// (tabs: home audio network bluetooth media calendar notifications).
// Esc or a click outside closes it.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs
import qs.ui
import qs.cc

Scope {
    IpcHandler {
        target: "controlcenter"
        function toggle(tab: string): void { Panels.toggle(tab); }
        function open(tab: string): void { Panels.show(tab); }
        function close(): void { Panels.close(); }
    }

    PanelWindow {
        id: win
        // 0 = closed, 1 = open. The card grows out of the bar item that opened
        // it (Panels.sourceX): fast start and soft landing on open, quicker close.
        property real progress: 0
        NumberAnimation {
            id: openAnim
            target: win; property: "progress"; to: 1
            duration: Theme.dur(300); easing.type: Easing.OutQuint
        }
        NumberAnimation {
            id: closeAnim
            target: win; property: "progress"; to: 0
            duration: Theme.dur(180); easing.type: Easing.InCubic
        }
        Connections {
            target: Panels
            function onOpenChanged() {
                if (Panels.open) { closeAnim.stop(); openAnim.start(); }
                else { openAnim.stop(); closeAnim.start(); }
            }
        }

        // Stay mapped until the close animation finishes.
        visible: Panels.open || progress > 0
        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]

        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "quickshell-controlcenter"
        WlrLayershell.keyboardFocus: Panels.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Normal      // sits below the bar, bar stays clickable
        anchors { top: true; bottom: true; left: true; right: true }
        color: Qt.alpha(Theme.backdrop, Theme.backdrop.a * progress)

        MouseArea {
            anchors.fill: parent
            onClicked: Panels.close()
        }

        Rectangle {
            id: card
            anchors { top: parent.top; right: parent.right; topMargin: 8; rightMargin: 8 }
            width: 800
            height: Math.min(660, parent.height - 16)
            radius: Theme.radius
            color: Theme.panel
            border.width: 1
            border.color: Theme.border

            opacity: Math.min(1, win.progress * 1.6)
            transform: Scale {
                // Source point in card coordinates, top edge.
                origin.x: Panels.sourceX < 0 ? card.width - 40
                    : Math.max(0, Math.min(card.width, Panels.sourceX - card.x))
                origin.y: 0
                xScale: 0.86 + 0.14 * win.progress
                yScale: 0.86 + 0.14 * win.progress
            }

            focus: Panels.open
            Keys.onEscapePressed: Panels.close()

            MouseArea { anchors.fill: parent }   // clicks inside don't close

            RowLayout {
                anchors { fill: parent; margins: 12 }
                spacing: 12

                // Sidebar
                ColumnLayout {
                    // Fixed width: children fill it, which would otherwise make
                    // this column grab space from the content area.
                    Layout.fillWidth: false
                    Layout.preferredWidth: 172
                    Layout.maximumWidth: 172
                    Layout.fillHeight: true
                    spacing: 4

                    Repeater {
                        model: Panels.tabs
                        delegate: Rectangle {
                            required property var modelData
                            readonly property bool current: Panels.tab === modelData.id
                            Layout.fillWidth: true
                            implicitHeight: 40
                            radius: Theme.radiusSmall
                            color: current ? Theme.accentSoft : tabMouse.containsMouse ? Theme.cardHover : "transparent"
                            Behavior on color { ColorAnimation { duration: Theme.anim } }

                            RowLayout {
                                anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                                spacing: 12
                                SymbolIcon { icon: modelData.icon; size: 16; color: current ? Theme.accent : Theme.muted }
                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.label
                                    color: current ? Theme.accent : Theme.fg
                                    font.family: Theme.font
                                    font.pixelSize: Theme.fontSize
                                    font.weight: current ? Font.DemiBold : Font.Normal
                                }
                                Rectangle {
                                    visible: modelData.id === "notifications" && NotificationService.history.count > 0
                                    implicitWidth: Math.max(20, count.implicitWidth + 10); implicitHeight: 18; radius: 9
                                    color: Theme.surface0
                                    Text {
                                        id: count
                                        anchors.centerIn: parent
                                        text: NotificationService.history.count
                                        color: Theme.muted
                                        font.family: Theme.font
                                        font.pixelSize: Theme.fontSize - 3
                                    }
                                }
                            }
                            MouseArea {
                                id: tabMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Panels.tab = modelData.id
                            }
                        }
                    }
                    Item { Layout.fillHeight: true }
                }

                Rectangle { Layout.fillHeight: true; implicitWidth: 1; color: Theme.border }

                // Content
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: 4
                        Text {
                            Layout.fillWidth: true
                            text: Panels.tabs.find(t => t.id === Panels.tab)?.label ?? ""
                            color: Theme.fg
                            font.family: Theme.font
                            font.pixelSize: 20
                            font.weight: Font.DemiBold
                        }
                        IconButton { size: 30; icon: "window-close-symbolic"; onClicked: Panels.close() }
                    }

                    Loader {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        active: win.visible
                        sourceComponent: ({
                            home: homeTab, audio: audioTab, network: networkTab, bluetooth: bluetoothTab,
                            media: mediaTab, calendar: calendarTab, notifications: notificationsTab,
                            settings: settingsTab,
                        })[Panels.tab] ?? homeTab
                    }
                }
            }
        }

        Component { id: homeTab; HomeTab {} }
        Component { id: audioTab; AudioTab {} }
        Component { id: networkTab; NetworkTab {} }
        Component { id: bluetoothTab; BluetoothTab {} }
        Component { id: mediaTab; MediaTab {} }
        Component { id: calendarTab; CalendarTab {} }
        Component { id: notificationsTab; NotificationsTab {} }
        Component { id: settingsTab; SettingsTab {} }
    }
}
