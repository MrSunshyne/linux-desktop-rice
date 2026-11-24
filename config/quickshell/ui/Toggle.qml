// On/off switch. Emits toggled(); the owner updates `checked` from real state.
import QtQuick
import qs

Rectangle {
    id: root
    property bool checked: false
    signal toggled()

    implicitWidth: 42
    implicitHeight: 24
    radius: height / 2
    color: checked ? Theme.accent : Theme.surface1
    Behavior on color { ColorAnimation { duration: Theme.anim } }

    Rectangle {
        width: 18; height: 18; radius: 9
        anchors.verticalCenter: parent.verticalCenter
        x: root.checked ? parent.width - width - 3 : 3
        color: root.checked ? Theme.accentInk : Theme.text
        Behavior on x { NumberAnimation { duration: Theme.anim; easing.type: Easing.OutCubic } }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}
