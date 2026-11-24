// Output and input volume, device selection, per-app volume.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import qs
import qs.ui

Flickable {
    id: root
    contentHeight: column.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    readonly property var nodes: Pipewire.nodes.values.filter(n => n.audio)
    readonly property var sinks: nodes.filter(n => n.isSink && !n.isStream)
    readonly property var sources: nodes.filter(n => !n.isSink && !n.isStream)
    readonly property var streams: nodes.filter(n => n.isStream && !n.isSink)

    // Track every audio node while this tab is open so volumes are live.
    PwObjectTracker { objects: root.nodes }

    function appIcon(n) {
        const p = n.properties ?? {};
        const icon = p["application.icon-name"] || p["application.process.binary"] || "";
        const entry = DesktopEntries.heuristicLookup(p["application.name"] || icon);
        return Quickshell.iconPath(entry?.icon || icon, "application-x-executable");
    }
    function appName(n) {
        const p = n.properties ?? {};
        return (p["application.name"] || AudioService.nodeName(n)) + (p["media.name"] ? " · " + p["media.name"] : "");
    }

    ColumnLayout {
        id: column
        width: root.width
        spacing: 10

        SectionTitle { text: "OUTPUT" }
        Card {
            Layout.fillWidth: true
            VolumeRow { node: AudioService.sink }
            Repeater {
                model: root.sinks.length > 1 ? root.sinks : []
                delegate: ListItem {
                    required property var modelData
                    icon: "audio-speakers-symbolic"
                    title: AudioService.nodeName(modelData)
                    active: modelData === AudioService.sink
                    onClicked: Pipewire.preferredDefaultAudioSink = modelData
                }
            }
        }

        SectionTitle { text: "INPUT"; visible: root.sources.length > 0 }
        Card {
            Layout.fillWidth: true
            visible: root.sources.length > 0
            VolumeRow { node: AudioService.source; isInput: true }
            Repeater {
                model: root.sources.length > 1 ? root.sources : []
                delegate: ListItem {
                    required property var modelData
                    icon: "audio-input-microphone-symbolic"
                    title: AudioService.nodeName(modelData)
                    active: modelData === AudioService.source
                    onClicked: Pipewire.preferredDefaultAudioSource = modelData
                }
            }
        }

        SectionTitle { text: "APPLICATIONS" }
        Card {
            Layout.fillWidth: true
            Text {
                visible: root.streams.length === 0
                text: "No apps are playing sound"
                color: Theme.dim
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 1
            }
            Repeater {
                model: root.streams
                delegate: VolumeRow {
                    required property var modelData
                    node: modelData
                    label: root.appName(modelData)
                    image: root.appIcon(modelData)
                }
            }
        }
    }
}
