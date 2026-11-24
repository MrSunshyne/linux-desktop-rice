pragma Singleton
// Default output/input from PipeWire, shared by the bar and the Audio tab.
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource

    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? true
    readonly property real micVolume: source?.audio?.volume ?? 0
    readonly property bool micMuted: source?.audio?.muted ?? true

    // PipeWire only reports volume/mute for tracked nodes.
    property var tracker: PwObjectTracker { objects: [root.sink, root.source] }

    function setVolume(node, v) {
        if (node?.audio) node.audio.volume = Math.max(0, Math.min(1, v));
    }
    function toggleMute(node) {
        if (node?.audio) node.audio.muted = !node.audio.muted;
    }

    function outputIcon(v, m) {
        return m || v <= 0 ? "audio-volume-muted-symbolic"
             : v < 0.34 ? "audio-volume-low-symbolic"
             : v < 0.67 ? "audio-volume-medium-symbolic"
             : "audio-volume-high-symbolic";
    }
    function inputIcon(m) {
        return m ? "microphone-sensitivity-muted-symbolic" : "microphone-sensitivity-high-symbolic";
    }
    function nodeName(n) {
        return n?.description || n?.nickname || n?.name || "Unknown";
    }
}
