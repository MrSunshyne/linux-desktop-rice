// Small picker that drops down under a bar icon: Wi-Fi or Bluetooth.
// Left-click the icon to toggle; Esc or a click outside closes it.
// `qs ipc call picker toggle wifi|bluetooth` opens it under the icon's last position.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Wayland
import qs.ui

Scope {
    IpcHandler {
        target: "picker"
        function toggle(kind: string): void { Panels.togglePicker(kind); }
        function close(): void { Panels.closePicker(); }
    }

    PanelWindow {
        id: win
        readonly property bool shown: Panels.picker !== ""
        // Keep the last kind while fading out so the content doesn't vanish early.
        property string kind: "wifi"
        // 0 = closed, 1 = open. Grows out of the bar icon (Panels.pickerX).
        property real progress: 0
        NumberAnimation {
            id: openAnim
            target: win; property: "progress"; to: 1
            duration: Theme.dur(280); easing.type: Easing.OutQuint
        }
        NumberAnimation {
            id: closeAnim
            target: win; property: "progress"; to: 0
            duration: Theme.dur(160); easing.type: Easing.InCubic
        }
        onShownChanged: if (shown) { closeAnim.stop(); openAnim.start(); } else { openAnim.stop(); closeAnim.start(); }
        Connections {
            target: Panels
            function onPickerChanged() {
                if (Panels.picker === "") return;
                // Switching straight to the other picker: re-grow from its icon.
                if (win.kind !== Panels.picker && win.progress > 0) { win.progress = 0.4; openAnim.restart(); }
                win.kind = Panels.picker;
            }
        }

        readonly property var adapter: Bluetooth.defaultAdapter
        readonly property var kinds: ({
            wifi: {
                title: "Wi-Fi",
                icon: "network-wireless-symbolic",
                hasToggle: NetworkService.wifiDevice !== null,
                on: Networking.wifiEnabled,
                toggle: () => Networking.wifiEnabled = !Networking.wifiEnabled,
                more: "More network settings",
                tab: "network",
            },
            bluetooth: {
                title: "Bluetooth",
                icon: "bluetooth-active-symbolic",
                hasToggle: adapter !== null,
                on: adapter?.enabled ?? false,
                toggle: () => adapter.enabled = !adapter.enabled,
                more: "More Bluetooth settings",
                tab: "bluetooth",
            },
        })
        readonly property var info: kinds[kind]

        visible: shown || progress > 0
        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]

        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "quickshell-picker"
        WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Normal      // below the bar
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"

        MouseArea {
            anchors.fill: parent
            onClicked: Panels.closePicker()
        }

        Rectangle {
            id: card
            width: 380
            height: Math.min(content.implicitHeight + 28, 560)
            // Centred under the icon, kept on screen.
            x: Math.max(Theme.barGap, Math.min(win.width - width - Theme.barGap, Panels.pickerX - width / 2))
            Behavior on height { enabled: win.progress === 1; NumberAnimation { duration: Theme.anim; easing.type: Easing.OutCubic } }
            y: 8
            radius: Theme.radius
            color: Theme.panel
            border.width: 1
            border.color: Theme.border
            clip: true

            opacity: Math.min(1, win.progress * 1.6)
            transform: Scale {
                origin.x: Math.max(0, Math.min(card.width, Panels.pickerX - card.x))
                origin.y: 0
                xScale: 0.86 + 0.14 * win.progress
                yScale: 0.86 + 0.14 * win.progress
            }

            focus: win.shown
            Keys.onEscapePressed: Panels.closePicker()

            MouseArea { anchors.fill: parent }   // clicks inside don't close

            ColumnLayout {
                id: content
                anchors { fill: parent; margins: 14 }
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    SymbolIcon { icon: win.info.icon; size: 18; color: Theme.fg }
                    Text {
                        Layout.fillWidth: true
                        text: win.info.title
                        color: Theme.fg
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize + 3
                        font.weight: Font.DemiBold
                    }
                    Toggle {
                        visible: win.info.hasToggle
                        checked: win.info.on
                        onToggled: win.info.toggle()
                    }
                }

                // Ethernet line in the Wi-Fi picker, since the bar icon shows
                // wired when both are up.
                ListItem {
                    visible: win.kind === "wifi" && NetworkService.wiredDevice !== null
                    interactive: false
                    icon: "network-wired-symbolic"
                    title: "Ethernet"
                    subtitle: NetworkService.wiredUp ? "Connected" + (NetworkService.wiredDevice.linkSpeed > 0 ? " · " + NetworkService.wiredDevice.linkSpeed + " Mb/s" : "")
                        : "Not connected"
                    active: NetworkService.wiredUp
                }

                Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.border }

                Flickable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    implicitHeight: Math.min(list.implicitHeight, 400)
                    contentHeight: list.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    Loader {
                        id: list
                        width: parent.width
                        // Created while visible so scanning only runs then.
                        active: win.visible
                        sourceComponent: win.kind === "bluetooth" ? bluetoothList : wifiList
                    }
                }

                TextButton {
                    text: win.info.more
                    onClicked: Panels.show(win.info.tab, Panels.pickerX)
                }
            }
        }

        Component { id: wifiList; WifiList {} }
        Component { id: bluetoothList; BluetoothList {} }
    }
}
