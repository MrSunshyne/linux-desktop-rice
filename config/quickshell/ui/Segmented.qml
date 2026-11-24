// Row of mutually exclusive options. `options`: [{ value, label }].
import QtQuick
import QtQuick.Layouts
import qs

Rectangle {
    id: root
    property var options: []
    property var current
    property var disabled: []          // values that can't be picked right now
    signal picked(var value)

    Layout.fillWidth: true
    implicitHeight: 34
    radius: Math.min(height / 2, Theme.radiusCard)
    color: Qt.alpha(Theme.sheen, Theme.dark ? 0.04 : 0.03)
    border.width: 1
    border.color: Theme.border

    RowLayout {
        anchors { fill: parent; margins: 3 }
        spacing: 3

        Repeater {
            model: root.options
            delegate: Rectangle {
                required property var modelData
                readonly property bool selected: modelData.value === root.current
                readonly property bool off: root.disabled.includes(modelData.value)
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Math.min(height / 2, Theme.radiusSmall)
                color: selected ? Theme.accent : mouse.containsMouse && !off ? Theme.cardHover : "transparent"
                Behavior on color { ColorAnimation { duration: Theme.anim } }

                Text {
                    anchors.centerIn: parent
                    text: modelData.label
                    color: selected ? Theme.accentInk : off ? Theme.dim : Theme.fg
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 1
                    font.weight: selected ? Font.DemiBold : Font.Normal
                }
                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: !off
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.picked(modelData.value)
                }
            }
        }
    }
}
