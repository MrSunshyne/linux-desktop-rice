// Home-tab tile: icon, label, state line. Click toggles; the arrow opens
// the related tab (if `target` is set).
import QtQuick
import QtQuick.Layouts
import qs

Rectangle {
    id: root
    property string icon
    property string label
    property string status
    property bool checked: false
    property string target: ""      // Panels tab id opened by the arrow

    signal toggled()

    Layout.fillWidth: true
    implicitHeight: 60
    radius: Theme.radiusCard
    color: checked ? Theme.accent : mouse.containsMouse ? Theme.cardHover : Theme.card
    border.width: checked ? 0 : 1
    border.color: Theme.border
    Behavior on color { ColorAnimation { duration: Theme.anim } }

    readonly property color ink: checked ? Theme.accentInk : Theme.fg

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }

    RowLayout {
        anchors { fill: parent; leftMargin: 14; rightMargin: 8 }
        spacing: 12

        SymbolIcon { icon: root.icon; size: 18; color: root.ink }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1
            Text {
                Layout.fillWidth: true
                text: root.label
                elide: Text.ElideRight
                color: root.ink
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
                font.weight: Font.DemiBold
            }
            Text {
                Layout.fillWidth: true
                text: root.status
                elide: Text.ElideRight
                color: root.checked ? Qt.alpha(Theme.accentInk, 0.75) : Theme.muted
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 2
            }
        }
        Rectangle {
            visible: root.target !== ""
            implicitWidth: 28; implicitHeight: 28; radius: 14
            color: arrow.containsMouse ? Qt.alpha(root.ink, 0.15) : "transparent"
            SymbolIcon { anchors.centerIn: parent; icon: "go-next-symbolic"; size: 14; color: root.ink }
            MouseArea {
                id: arrow
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Panels.show(root.target)
            }
        }
    }
}
