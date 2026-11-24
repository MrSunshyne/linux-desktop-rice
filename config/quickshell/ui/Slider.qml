// Thick rounded slider, 0..1. Drag, click or scroll; emits moved(value).
// `value` follows the real state; while dragging the fill follows the pointer.
import QtQuick
import qs

Item {
    id: root
    property real value: 0
    property bool dimmed: false
    property real step: 0.05
    signal moved(real value)

    readonly property real shown: mouse.pressed ? mouse.dragValue : value

    implicitHeight: 14
    implicitWidth: 200

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: Theme.surface0

        Rectangle {
            height: parent.height
            radius: parent.radius
            width: Math.max(height, parent.width * Math.max(0, Math.min(1, root.shown)))
            color: root.dimmed ? Qt.alpha(Theme.accent, 0.3) : Theme.accent
            Behavior on width { enabled: !mouse.pressed; NumberAnimation { duration: Theme.dur(250); easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: Theme.anim } }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        anchors.margins: -6
        cursorShape: Qt.PointingHandCursor
        property real dragValue: 0

        function update(x) {
            dragValue = Math.max(0, Math.min(1, (x - 6) / track.width));
            root.moved(dragValue);
        }
        onPressed: event => update(event.x)
        onPositionChanged: event => { if (pressed) update(event.x); }
        onWheel: wheel => root.moved(Math.max(0, Math.min(1, root.value + (wheel.angleDelta.y > 0 ? root.step : -root.step))))
    }
}
