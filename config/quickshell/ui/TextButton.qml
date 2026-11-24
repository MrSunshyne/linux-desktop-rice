// Small pill button with a label. `primary` fills it with the accent colour.
import QtQuick
import qs

Rectangle {
    id: root
    property string text
    property bool primary: false
    signal clicked()

    implicitWidth: label.implicitWidth + 24
    implicitHeight: 28
    radius: height / 2
    color: primary ? (mouse.containsMouse ? Qt.lighter(Theme.accent, 1.1) : Theme.accent)
        : mouse.containsMouse ? Theme.cardHover : Qt.alpha(Theme.surface0, 0.6)
    Behavior on color { ColorAnimation { duration: Theme.anim } }

    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: root.primary ? Theme.accentInk : Theme.fg
        font.family: Theme.font
        font.pixelSize: Theme.fontSize - 1
        font.weight: Font.Medium
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
