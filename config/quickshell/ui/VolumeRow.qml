// Mute button + label + slider + percentage for one PipeWire node.
// The node must be tracked (PwObjectTracker) by the owner.
import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs

RowLayout {
    id: root
    required property var node
    property string label: AudioService.nodeName(node)
    property bool isInput: false
    property string image: ""       // app icon for streams

    readonly property real volume: node?.audio?.volume ?? 0
    readonly property bool muted: node?.audio?.muted ?? false

    Layout.fillWidth: true
    spacing: 12

    IconButton {
        visible: root.image === ""
        size: 34
        icon: root.isInput ? AudioService.inputIcon(root.muted) : AudioService.outputIcon(root.volume, root.muted)
        ink: root.muted ? Theme.dim : Theme.fg
        onClicked: AudioService.toggleMute(root.node)
    }
    IconImage {
        visible: root.image !== ""
        source: root.image
        implicitSize: 28
        opacity: root.muted ? 0.4 : 1
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: AudioService.toggleMute(root.node) }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 6
        Text {
            Layout.fillWidth: true
            text: root.label
            elide: Text.ElideRight
            color: root.muted ? Theme.dim : Theme.fg
            font.family: Theme.font
            font.pixelSize: Theme.fontSize - 1
        }
        Slider {
            Layout.fillWidth: true
            value: root.volume
            dimmed: root.muted
            onMoved: v => AudioService.setVolume(root.node, v)
        }
    }

    Text {
        Layout.preferredWidth: 38
        Layout.alignment: Qt.AlignBottom
        horizontalAlignment: Text.AlignRight
        text: Math.round(root.volume * 100) + "%"
        color: root.muted ? Theme.dim : Theme.muted
        font.family: Theme.font
        font.pixelSize: Theme.fontSize - 1
    }
}
