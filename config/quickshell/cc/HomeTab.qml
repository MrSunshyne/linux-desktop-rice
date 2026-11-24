// Greeting, quick toggles, now playing, session actions.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Widgets
import qs
import qs.ui

ColumnLayout {
    id: root
    spacing: 14

    property string fullName: Quickshell.env("USER")
    property real uptime: 0

    // Display name from /etc/passwd (GECOS), falls back to $USER.
    Process {
        running: true
        command: ["sh", "-c", "getent passwd \"$USER\" | cut -d: -f5 | cut -d, -f1"]
        stdout: StdioCollector { onStreamFinished: if (text.trim() !== "") root.fullName = text.trim() }
    }
    Process {
        id: uptimeProc
        running: true
        command: ["cat", "/proc/uptime"]
        stdout: StdioCollector { onStreamFinished: root.uptime = parseFloat(text) }
    }
    Timer { interval: 60000; running: true; repeat: true; onTriggered: uptimeProc.running = true }

    SystemClock { id: clock; precision: SystemClock.Minutes }

    function greeting(h) {
        return h < 5 ? "Good night" : h < 12 ? "Good morning" : h < 18 ? "Good afternoon" : "Good evening";
    }
    function uptimeText(s) {
        const d = Math.floor(s / 86400), h = Math.floor(s % 86400 / 3600), m = Math.floor(s % 3600 / 60);
        return "Up " + (d ? d + " d " : "") + (h ? h + " h " : "") + m + " min";
    }

    // Greeting card
    Card {
        Layout.fillWidth: true
        padding: 18
        RowLayout {
            Layout.fillWidth: true
            spacing: 16

            Rectangle {
                implicitWidth: 56; implicitHeight: 56; radius: 28
                color: Theme.accentSoft
                border.width: 2
                border.color: Theme.accent
                Text {
                    anchors.centerIn: parent
                    text: root.fullName.charAt(0).toUpperCase()
                    color: Theme.accent
                    font.family: Theme.font
                    font.pixelSize: 24
                    font.weight: Font.Bold
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    text: root.greeting(clock.hours) + ", " + root.fullName.split(" ")[0]
                    color: Theme.fg
                    font.family: Theme.font
                    font.pixelSize: 19
                    font.weight: Font.DemiBold
                }
                Text {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    text: Qt.formatDate(clock.date, "dddd d MMMM") + "  ·  " + root.uptimeText(root.uptime)
                    color: Theme.muted
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 1
                }
            }
            Text {
                text: Qt.formatTime(clock.date, "HH:mm")
                color: Theme.fg
                font.family: Theme.font
                font.pixelSize: 34
                font.weight: Font.Light
            }
        }
    }

    // Quick toggles
    GridLayout {
        Layout.fillWidth: true
        columns: 2
        columnSpacing: 10
        rowSpacing: 10

        QuickToggle {
            icon: NetworkService.wifiNetwork ? NetworkService.signalIcon(NetworkService.wifiNetwork.signalStrength) : "network-wireless-symbolic"
            label: "Wi-Fi"
            status: !Networking.wifiEnabled ? "Off" : NetworkService.wifiNetwork?.name ?? "Not connected"
            checked: Networking.wifiEnabled
            target: "network"
            onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
        }
        QuickToggle {
            readonly property var adapter: Bluetooth.defaultAdapter
            readonly property var connectedDevices: adapter?.devices.values.filter(d => d.connected) ?? []
            icon: adapter?.enabled ? "bluetooth-active-symbolic" : "bluetooth-disabled-symbolic"
            label: "Bluetooth"
            status: !adapter ? "No adapter" : !adapter.enabled ? "Off"
                : connectedDevices.length === 1 ? connectedDevices[0].name
                : connectedDevices.length > 1 ? connectedDevices.length + " devices"
                : "On"
            checked: adapter?.enabled ?? false
            target: "bluetooth"
            onToggled: if (adapter) adapter.enabled = !adapter.enabled
        }
        QuickToggle {
            icon: AudioService.outputIcon(AudioService.volume, AudioService.muted)
            label: "Sound"
            status: AudioService.muted ? "Muted" : Math.round(AudioService.volume * 100) + "%"
            checked: !AudioService.muted
            target: "audio"
            onToggled: AudioService.toggleMute(AudioService.sink)
        }
        QuickToggle {
            icon: AudioService.inputIcon(AudioService.micMuted)
            label: "Microphone"
            status: AudioService.micMuted ? "Muted" : Math.round(AudioService.micVolume * 100) + "%"
            checked: !AudioService.micMuted
            target: "audio"
            onToggled: AudioService.toggleMute(AudioService.source)
        }
        QuickToggle {
            icon: NotificationService.dnd ? "notifications-disabled-symbolic" : "preferences-system-notifications-symbolic"
            label: "Do Not Disturb"
            status: NotificationService.dnd ? "On" : "Off"
            checked: NotificationService.dnd
            target: "notifications"
            onToggled: NotificationService.dnd = !NotificationService.dnd
        }
        QuickToggle {
            readonly property var player: MediaService.active
            icon: player?.isPlaying ? "media-playback-pause-symbolic" : "media-playback-start-symbolic"
            label: player?.trackTitle || "Media"
            status: player ? (player.trackArtist || player.identity) : "Nothing playing"
            checked: player?.isPlaying ?? false
            target: "media"
            onToggled: if (player?.canTogglePlaying) player.togglePlaying()
        }
    }

    Item { Layout.fillHeight: true }

    // Session actions
    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        Repeater {
            model: [
                { label: "Lock",      icon: "system-lock-screen-symbolic", cmd: ["loginctl", "lock-session"] },
                { label: "Log out",   icon: "system-log-out-symbolic",     cmd: ["hyprctl", "dispatch", "hl.dsp.exit()"] },
                { label: "Restart",   icon: "system-reboot-symbolic",      cmd: ["systemctl", "reboot"] },
                { label: "Shut down", icon: "system-shutdown-symbolic",    cmd: ["systemctl", "poweroff"] },
            ]
            delegate: Rectangle {
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: 64
                radius: Theme.radiusCard
                color: area.containsMouse ? (modelData.label === "Shut down" ? Qt.alpha(Theme.red, 0.2) : Theme.cardHover) : Theme.card
                border.width: 1
                border.color: Theme.border
                Behavior on color { ColorAnimation { duration: Theme.anim } }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 6
                    SymbolIcon {
                        Layout.alignment: Qt.AlignHCenter
                        icon: modelData.icon
                        size: 18
                        color: area.containsMouse && modelData.label === "Shut down" ? Theme.red : Theme.fg
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: modelData.label
                        color: Theme.muted
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize - 2
                    }
                }
                MouseArea {
                    id: area
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Panels.close();
                        Quickshell.execDetached(modelData.cmd);
                    }
                }
            }
        }
    }
}
