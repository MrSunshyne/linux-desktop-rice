// Desktop wallpaper, drawn on the background layer of one screen.
// The picture path lives in Theme.qml.
import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    required property var modelData
    screen: modelData

    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "quickshell-wallpaper"
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: "black"

    Image {
        anchors.fill: parent
        source: Theme.wallpaper
        fillMode: Image.PreserveAspectCrop   // GNOME's "zoom"
        // Decode at screen size: sharp SVGs, and big photos don't sit in memory at full size.
        sourceSize: Qt.size(width * modelData.devicePixelRatio, height * modelData.devicePixelRatio)
        asynchronous: true
        cache: false
    }
}
