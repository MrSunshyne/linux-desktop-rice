// Volume pop-up near the bottom of the screen when output volume or mute
// changes (keys, scrolling, other apps). Click-through; hides after 1.5 s.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.ui

Scope {
    id: root
    property bool shown: false
    property bool ready: false      // ignore the initial values at startup

    Timer { interval: 1500; running: true; onTriggered: root.ready = true }
    Timer { id: hide; interval: 1500; onTriggered: root.shown = false }

    function poke() {
        if (!ready || Panels.isOpen("audio")) return;
        shown = true;
        hide.restart();
    }
    Connections {
        target: AudioService
        function onVolumeChanged() { root.poke(); }
        function onMutedChanged() { root.poke(); }
    }

    PanelWindow {
        visible: root.shown || box.opacity > 0
        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell-osd"
        exclusionMode: ExclusionMode.Ignore
        anchors { bottom: true }
        margins { bottom: 90 }
        implicitWidth: 320
        implicitHeight: 56
        color: "transparent"
        mask: Region {}             // never takes clicks

        Rectangle {
            id: box
            anchors.fill: parent
            radius: height / 2
            color: Theme.panel
            border.width: 1
            border.color: Theme.border
            opacity: root.shown ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.anim } }

            RowLayout {
                anchors { fill: parent; leftMargin: 20; rightMargin: 20 }
                spacing: 14
                SymbolIcon {
                    icon: AudioService.outputIcon(AudioService.volume, AudioService.muted)
                    size: 20
                    color: AudioService.muted ? Theme.dim : Theme.fg
                }
                Slider {
                    Layout.fillWidth: true
                    implicitHeight: 10
                    value: AudioService.volume
                    dimmed: AudioService.muted
                }
                Text {
                    Layout.preferredWidth: 36
                    horizontalAlignment: Text.AlignRight
                    text: AudioService.muted ? "Muted" : Math.round(AudioService.volume * 100) + "%"
                    color: AudioService.muted ? Theme.dim : Theme.fg
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                }
            }
        }
    }
}
