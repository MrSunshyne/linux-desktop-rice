// Round icon button. `checked` fills it with the accent colour.
import QtQuick
import qs

Rectangle {
    id: root
    property string icon
    property bool checked: false
    property int size: 36
    property color ink: checked ? Theme.accentInk : Theme.fg
    property string tooltip: ""

    signal clicked()

    implicitWidth: size
    implicitHeight: size
    radius: size / 2
    color: checked ? Theme.accent : mouse.containsMouse ? Theme.cardHover : Qt.alpha(Theme.surface0, 0.5)
    Behavior on color { ColorAnimation { duration: Theme.anim } }

    SymbolIcon {
        anchors.centerIn: parent
        icon: root.icon
        size: Math.round(root.size * 0.45)
        color: root.ink
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
