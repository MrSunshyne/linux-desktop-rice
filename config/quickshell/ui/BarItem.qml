// Icon and/or text in the bar. Lights up (accent) while its panel is open.
import QtQuick
import QtQuick.Layouts
import qs

Item {
    id: root
    property string icon
    property string text
    property bool active: false
    property bool dimmed: false
    property bool badge: false          // small dot, e.g. unread notifications
    property int maxTextWidth: 0        // 0 = no limit; longer text is elided

    signal clicked()
    signal rightClicked()
    signal scrolled(int steps)

    readonly property color ink: active ? Theme.accent
        : dimmed ? Theme.dim
        : mouse.containsMouse ? Theme.text : Theme.muted

    implicitWidth: row.implicitWidth
    implicitHeight: 22

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 6

        SymbolIcon {
            visible: root.icon !== ""
            icon: root.icon
            color: root.ink

            Rectangle {
                visible: root.badge
                width: 7; height: 7; radius: 3.5
                color: Theme.accent
                anchors { right: parent.right; top: parent.top; rightMargin: -2; topMargin: -2 }
            }
        }
        Text {
            visible: root.text !== ""
            Layout.maximumWidth: root.maxTextWidth > 0 ? root.maxTextWidth : -1
            elide: Text.ElideRight
            text: root.text
            color: root.active ? Theme.accent : Theme.fg
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
            Behavior on color { ColorAnimation { duration: Theme.anim } }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: event => event.button === Qt.RightButton ? root.rightClicked() : root.clicked()
        onWheel: wheel => root.scrolled(wheel.angleDelta.y > 0 ? 1 : -1)
    }
}
