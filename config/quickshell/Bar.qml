// Top bar. Left: launcher + workspaces. Centre: focused window.
// Right: tray, now playing, status (network, bluetooth, volume,
// notifications), clock, session. Status items open the matching
// Control Center tab; scroll on the volume changes it.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import Quickshell.Wayland
import qs.ui

PanelWindow {
    WlrLayershell.namespace: "quickshell-bar"
    id: bar
    required property var modelData
    screen: modelData

    // Floating: transparent window inset from the edges, rounded body inside.
    anchors { top: true; left: true; right: true }
    margins { top: Theme.barGap; left: Theme.barGap; right: Theme.barGap }
    implicitHeight: Theme.barHeight
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        radius: Theme.barRadius          // 0 when the bar is edge-to-edge
        color: Theme.bg
        border.width: 1
        border.color: Theme.border
    }

    readonly property var monitor: Hyprland.monitorFor(modelData)

    // Screen x of an item's centre: panels grow out of this point.
    function centerX(item) { return item.mapToItem(null, item.width / 2, 0).x + Theme.barGap; }

    // Left: launcher button + workspaces
    RowLayout {
        anchors { left: parent.left; leftMargin: 6; verticalCenter: parent.verticalCenter }
        spacing: 6

        Capsule {
            padding: 10
            BarItem {
                icon: "view-app-grid-symbolic"
                onClicked: Quickshell.execDetached(["qs", "ipc", "call", "launcher", "toggle"])
            }
        }

        Capsule {
            padding: 6
            spacing: 4
            Repeater {
                model: Hyprland.workspaces
                delegate: Rectangle {
                    required property var modelData
                    readonly property bool mine: modelData.id > 0 && modelData.monitor === bar.monitor
                    visible: mine
                    implicitWidth: !mine ? 0 : modelData.focused ? 34 : 22
                    implicitHeight: 18
                    radius: 9
                    color: modelData.focused ? Theme.accent
                        : modelData.urgent ? Theme.urgent
                        : wsMouse.containsMouse ? Theme.cardHover : "transparent"
                    Behavior on implicitWidth { NumberAnimation { duration: Theme.anim; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: Theme.anim } }

                    Text {
                        anchors.centerIn: parent
                        text: modelData.name
                        color: modelData.focused ? Theme.accentInk : Theme.muted
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize - 1
                        font.weight: modelData.focused ? Font.Bold : Font.Normal
                    }
                    MouseArea {
                        id: wsMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: modelData.activate()
                    }
                }
            }
        }
    }

    // Centre: focused window title
    Text {
        anchors.centerIn: parent
        width: Math.min(implicitWidth, parent.width * 0.3)
        elide: Text.ElideRight
        text: Hyprland.activeToplevel?.title ?? ""
        color: Theme.muted
        font.family: Theme.font
        font.pixelSize: Theme.fontSize
    }

    // Right
    RowLayout {
        anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
        spacing: 6

        // Tray
        Capsule {
            visible: SystemTray.items.values.length > 0
            spacing: 10
            Repeater {
                model: SystemTray.items
                delegate: IconImage {
                    id: trayIcon
                    required property var modelData
                    source: modelData.icon
                    implicitSize: 16

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -4
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                        onClicked: event => {
                            const item = trayIcon.modelData;
                            if (event.button === Qt.MiddleButton) {
                                item.secondaryActivate();
                            } else if (event.button === Qt.RightButton || item.onlyMenu) {
                                if (item.hasMenu) {
                                    const p = trayIcon.mapToItem(null, 0, trayIcon.height);
                                    item.display(bar, p.x, p.y + 8);
                                }
                            } else {
                                item.activate();
                            }
                        }
                        onWheel: wheel => trayIcon.modelData.scroll(wheel.angleDelta.y / 120, false)
                    }
                }
            }
        }

        // Now playing (only when a player exists)
        Capsule {
            visible: MediaService.active !== null
            BarItem {
                id: mediaItem
                readonly property var player: MediaService.active
                icon: player?.isPlaying ? "media-playback-pause-symbolic" : "media-playback-start-symbolic"
                text: player ? [player.trackTitle, player.trackArtist].filter(s => s).join(" · ") : ""
                maxTextWidth: 240
                active: Panels.isOpen("media")
                onClicked: Panels.toggle("media", bar.centerX(mediaItem))
                onRightClicked: if (player?.canTogglePlaying) player.togglePlaying()
            }
        }

        // Status
        Capsule {
            spacing: 14
            BarItem {
                id: netItem
                icon: NetworkService.icon
                dimmed: !NetworkService.online
                active: Panels.picker === "wifi" || Panels.isOpen("network")
                // Left: Wi-Fi picker under this icon. Right: full Network tab.
                onClicked: Panels.togglePicker("wifi", bar.centerX(netItem))
                onRightClicked: Panels.toggle("network", bar.centerX(netItem))
            }
            BarItem {
                id: btItem
                readonly property var adapter: Bluetooth.defaultAdapter
                readonly property bool anyConnected: adapter?.devices.values.some(d => d.connected) ?? false
                visible: adapter !== null
                icon: adapter?.enabled ? "bluetooth-active-symbolic" : "bluetooth-disabled-symbolic"
                dimmed: !(adapter?.enabled ?? false)
                badge: anyConnected                // dot while a device is connected
                active: Panels.picker === "bluetooth" || Panels.isOpen("bluetooth")
                // Left: Bluetooth picker under this icon. Right: full Bluetooth tab.
                onClicked: Panels.togglePicker("bluetooth", bar.centerX(btItem))
                onRightClicked: Panels.toggle("bluetooth", bar.centerX(btItem))
            }
            BarItem {
                id: volItem
                icon: AudioService.outputIcon(AudioService.volume, AudioService.muted)
                text: Math.round(AudioService.volume * 100) + "%"
                dimmed: AudioService.muted
                active: Panels.isOpen("audio")
                onClicked: Panels.toggle("audio", bar.centerX(volItem))
                onRightClicked: AudioService.toggleMute(AudioService.sink)
                onScrolled: steps => AudioService.setVolume(AudioService.sink, AudioService.volume + steps * 0.05)
            }
            BarItem {
                id: bellItem
                icon: NotificationService.dnd ? "notifications-disabled-symbolic" : "preferences-system-notifications-symbolic"
                badge: NotificationService.history.count > 0 && !NotificationService.dnd
                active: Panels.isOpen("notifications")
                onClicked: Panels.toggle("notifications", bar.centerX(bellItem))
            }
        }

        // Clock
        Capsule {
            SystemClock { id: clock; precision: SystemClock.Minutes }
            BarItem {
                id: clockItem
                text: Qt.formatDateTime(clock.date, "ddd d MMM   HH:mm")
                active: Panels.isOpen("calendar")
                onClicked: Panels.toggle("calendar", bar.centerX(clockItem))
            }
        }

        // Home / session
        Capsule {
            padding: 10
            BarItem {
                id: homeItem
                icon: "system-shutdown-symbolic"
                active: Panels.isOpen("home")
                onClicked: Panels.toggle("home", bar.centerX(homeItem))
            }
        }
    }
}
