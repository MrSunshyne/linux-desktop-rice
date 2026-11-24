// Small heading above a card, with optional widgets on the right.
import QtQuick
import QtQuick.Layouts
import qs

RowLayout {
    property string text
    default property alias actions: actionsRow.data

    Layout.fillWidth: true
    Layout.topMargin: 4
    spacing: 8

    Text {
        Layout.fillWidth: true
        text: parent.text
        color: Theme.muted
        font.family: Theme.font
        font.pixelSize: Theme.fontSize - 1
        font.weight: Font.DemiBold
        font.letterSpacing: 0.5
    }
    RowLayout { id: actionsRow; spacing: 8 }
}
