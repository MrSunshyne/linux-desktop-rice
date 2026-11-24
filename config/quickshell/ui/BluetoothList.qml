// Paired and nearby Bluetooth devices. Click a paired device to connect or
// disconnect, the bin to forget it; click a nearby one to pair.
// Used by the Bluetooth tab and the bar's Bluetooth picker. Scans while it exists.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import qs

ColumnLayout {
    id: root
    Layout.fillWidth: true
    spacing: 2

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool on: adapter?.enabled ?? false
    readonly property var devices: adapter?.devices.values ?? []
    readonly property var paired: devices.filter(d => d.paired || d.bonded)
        .sort((a, b) => (b.connected - a.connected) || a.name.localeCompare(b.name))
    // Unpaired devices that announce a real name (skips raw MAC-only entries).
    readonly property var nearby: devices.filter(d => !d.paired && !d.bonded && d.deviceName !== "")

    function startScan() { if (adapter && adapter.enabled && !adapter.discovering) adapter.discovering = true; }
    Component.onCompleted: startScan()
    onOnChanged: startScan()
    Component.onDestruction: if (adapter && adapter.discovering) adapter.discovering = false

    function deviceIcon(d) {
        const name = (d.icon || "bluetooth-active") + "-symbolic";
        return Quickshell.iconPath(name, true) !== "" ? name : "bluetooth-active-symbolic";
    }
    function status(d) {
        const s = d.pairing ? "Pairing…"
            : d.state === BluetoothDeviceState.Connecting ? "Connecting…"
            : d.state === BluetoothDeviceState.Disconnecting ? "Disconnecting…"
            : d.connected ? "Connected" : d.paired ? "Paired" : "Available";
        return s + (d.batteryAvailable ? " · " + Math.round(d.battery * 100) + "% battery" : "");
    }

    component Hint: Text {
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        color: Theme.dim
        font.family: Theme.font
        font.pixelSize: Theme.fontSize - 1
    }

    Hint {
        visible: !root.on
        text: root.adapter ? "Bluetooth is off" : "No Bluetooth adapter found"
    }

    SectionTitle { visible: root.on; text: "PAIRED" }
    Hint { visible: root.on && root.paired.length === 0; text: "No paired devices" }
    Repeater {
        model: root.on ? root.paired : []
        delegate: ListItem {
            required property var modelData
            icon: root.deviceIcon(modelData)
            title: modelData.name
            subtitle: root.status(modelData)
            active: modelData.connected
            onClicked: modelData.connected ? modelData.disconnect() : modelData.connect()
            IconButton {
                size: 28
                icon: "user-trash-symbolic"
                ink: Theme.dim
                onClicked: modelData.forget()
            }
        }
    }

    SectionTitle {
        visible: root.on
        Layout.topMargin: 10
        text: "NEARBY"
        Text {
            visible: root.adapter?.discovering ?? false
            text: "Scanning…"
            color: Theme.accent
            font.family: Theme.font
            font.pixelSize: Theme.fontSize - 2
        }
    }
    Hint { visible: root.on && root.nearby.length === 0; text: "Looking for devices. Put the device in pairing mode." }
    Repeater {
        model: root.on ? root.nearby : []
        delegate: ListItem {
            required property var modelData
            icon: root.deviceIcon(modelData)
            title: modelData.name
            subtitle: root.status(modelData)
            // Trust first so it reconnects automatically later.
            onClicked: { modelData.trusted = true; modelData.pair(); }
        }
    }
}
