// Clickable row: icon, title, subtitle, and an optional trailing area.
// Use `icon` for theme symbolic icons or `image` for full-colour app icons.
import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs

Rectangle {
    id: root
    property string icon
    property string image
    property string title
    property string subtitle
    property bool active: false
    property bool interactive: true
    default property alias trailing: trail.data

    signal clicked()

    Layout.fillWidth: true
    implicitHeight: Math.max(48, body.implicitHeight + 16)
    radius: Theme.radiusSmall
    color: active ? Theme.accentSoft
        : interactive && mouse.containsMouse ? Theme.cardHover : "transparent"
    Behavior on color { ColorAnimation { duration: Theme.anim } }

    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: root.interactive
        hoverEnabled: true
        cursorShape: root.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.clicked()
    }

    RowLayout {
        id: body
        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 10; rightMargin: 10 }
        spacing: 12

        SymbolIcon {
            visible: root.icon !== "" && root.image === ""
            icon: root.icon
            size: 18
            color: root.active ? Theme.accent : Theme.fg
        }
        IconImage {
            visible: root.image !== ""
            source: root.image
            implicitSize: 24
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1
            Text {
                Layout.fillWidth: true
                text: root.title
                elide: Text.ElideRight
                color: root.active ? Theme.accent : Theme.fg
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
            }
            Text {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.subtitle
                elide: Text.ElideRight
                color: Theme.muted
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 2
            }
        }
        RowLayout {
            id: trail
            spacing: 8
        }
    }
}
