// Rounded pill that groups items in the bar.
import QtQuick
import QtQuick.Layouts
import qs

Rectangle {
    default property alias content: row.data
    property int padding: 12
    property alias spacing: row.spacing

    implicitWidth: row.implicitWidth + padding * 2
    implicitHeight: Theme.barHeight - 8
    radius: Math.min(height / 2, Theme.radius)
    color: Theme.card
    border.width: 1
    border.color: Theme.border

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 12
    }
}
