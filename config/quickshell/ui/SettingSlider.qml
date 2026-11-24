// Label + current value + slider over [from, to], snapped to `step`.
import QtQuick
import QtQuick.Layouts
import qs

ColumnLayout {
    id: root
    property string label
    property string valueText
    property real from: 0
    property real to: 1
    property real step: 0.1
    property real value: 0
    signal moved(real value)

    Layout.fillWidth: true
    spacing: 8

    function snap(v) { return Math.max(from, Math.min(to, Math.round(v / step) * step)); }

    RowLayout {
        Layout.fillWidth: true
        Text {
            Layout.fillWidth: true
            text: root.label
            color: Theme.fg
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
        }
        Text {
            text: root.valueText
            color: Theme.muted
            font.family: Theme.font
            font.pixelSize: Theme.fontSize - 1
        }
    }
    Slider {
        Layout.fillWidth: true
        implicitHeight: 8
        value: (root.value - root.from) / (root.to - root.from)
        step: root.step / (root.to - root.from)
        onMoved: v => root.moved(root.snap(root.from + v * (root.to - root.from)))
    }
}
