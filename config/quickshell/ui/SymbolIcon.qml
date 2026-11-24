// A theme "-symbolic" icon recoloured to `color`. Adwaita's symbolic SVGs are
// black, which would be invisible on the dark bar, so the icon is used as an
// alpha mask over a solid colour.
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import qs

Item {
    id: root
    property string icon
    property color color: Theme.fg
    Behavior on color { ColorAnimation { duration: Theme.anim } }
    property int size: 16

    implicitWidth: size
    implicitHeight: size

    IconImage {
        id: mask
        anchors.fill: parent
        implicitSize: root.size
        source: Quickshell.iconPath(root.icon, true)
        visible: false
        layer.enabled: true
    }

    Rectangle {
        id: fill
        anchors.fill: parent
        color: root.color
        visible: false
        layer.enabled: true
    }

    MultiEffect {
        anchors.fill: parent
        source: fill
        maskEnabled: true
        maskSource: mask
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1.0
    }
}
