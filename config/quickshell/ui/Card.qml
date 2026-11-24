// Rounded section inside a panel. Children stack vertically.
import QtQuick
import QtQuick.Layouts
import qs

Rectangle {
    default property alias content: column.data
    property int padding: 14
    property alias spacing: column.spacing

    implicitHeight: column.implicitHeight + padding * 2
    radius: Theme.radiusCard
    color: Theme.card
    border.width: 1
    border.color: Theme.border

    ColumnLayout {
        id: column
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: parent.padding }
        spacing: 10
    }
}
