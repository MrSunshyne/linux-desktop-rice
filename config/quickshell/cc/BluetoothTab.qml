// Adapter power plus the device list (ui/BluetoothList.qml, shared with the
// bar's Bluetooth picker).
import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import qs
import qs.ui

Flickable {
    id: root
    contentHeight: column.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    readonly property var adapter: Bluetooth.defaultAdapter

    ColumnLayout {
        id: column
        width: root.width
        spacing: 10

        SectionTitle {
            text: "BLUETOOTH"
            Toggle {
                visible: root.adapter !== null
                checked: root.adapter?.enabled ?? false
                onToggled: root.adapter.enabled = !root.adapter.enabled
            }
        }

        Card {
            Layout.fillWidth: true
            BluetoothList {}
        }
    }
}
