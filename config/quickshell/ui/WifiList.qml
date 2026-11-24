// Wi-Fi networks with connect / password / disconnect / forget.
// Used by the Network tab and the bar's Wi-Fi picker. Scans while it exists.
import QtQuick
import QtQuick.Layouts
import Quickshell.Networking
import qs

ColumnLayout {
    id: root
    Layout.fillWidth: true
    spacing: 2

    readonly property var wifi: NetworkService.wifiDevice
    // Connected first, then saved, then by signal. Hidden networks are skipped.
    readonly property var networks: (wifi?.networks.values ?? [])
        .filter(n => n.name !== "")
        .sort((a, b) => (b.connected - a.connected) || (b.known - a.known) || (b.signalStrength - a.signalStrength))

    property var expanded: null   // network showing its password field / actions
    property string error: ""

    Component.onCompleted: if (wifi) wifi.scannerEnabled = true
    Component.onDestruction: if (wifi) wifi.scannerEnabled = false

    Text {
        visible: !root.wifi || !Networking.wifiEnabled || root.networks.length === 0
        text: !root.wifi ? "No Wi-Fi adapter" : !Networking.wifiEnabled ? "Wi-Fi is off" : "Searching for networks…"
        color: Theme.dim
        font.family: Theme.font
        font.pixelSize: Theme.fontSize - 1
    }

    Repeater {
        model: Networking.wifiEnabled ? root.networks : []
        delegate: ColumnLayout {
            id: entry
            required property var modelData
            readonly property var net: modelData
            readonly property bool secured: net.security !== WifiSecurityType.Open
            readonly property bool open: root.expanded === net
            Layout.fillWidth: true
            spacing: 4

            Connections {
                target: entry.net
                function onConnectionFailed(reason) {
                    root.error = entry.net.name + ": " + ConnectionFailReason.toString(reason);
                }
            }

            ListItem {
                icon: NetworkService.signalIcon(entry.net.signalStrength)
                title: entry.net.name
                subtitle: entry.net.stateChanging ? "Connecting…"
                    : entry.net.connected ? "Connected"
                    : entry.net.known ? "Saved"
                    : entry.secured ? "Secured" : "Open"
                active: entry.net.connected
                // Saved or open network: connect right away. Otherwise expand
                // (password field, or Disconnect/Forget when connected).
                onClicked: {
                    root.error = "";
                    if (!entry.net.connected && (entry.net.known || !entry.secured)) {
                        entry.net.connect();
                        root.expanded = null;
                    } else {
                        root.expanded = entry.open ? null : entry.net;
                    }
                }
                SymbolIcon {
                    visible: entry.secured
                    icon: "changes-prevent-symbolic"
                    size: 14
                    color: Theme.dim
                }
            }

            // Actions for the connected network
            RowLayout {
                visible: entry.open && entry.net.connected
                Layout.leftMargin: 40
                Layout.bottomMargin: 6
                spacing: 8
                TextButton { text: "Disconnect"; onClicked: { entry.net.disconnect(); root.expanded = null; } }
                TextButton { text: "Forget"; onClicked: { entry.net.forget(); root.expanded = null; } }
            }

            // Password for a new secured network
            RowLayout {
                visible: entry.open && !entry.net.connected && !entry.net.known && entry.secured
                Layout.fillWidth: true
                Layout.leftMargin: 40
                Layout.rightMargin: 8
                Layout.bottomMargin: 6
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 32
                    radius: Theme.radiusSmall
                    color: Theme.mantle
                    border.width: 1
                    border.color: pw.activeFocus ? Theme.accent : Theme.border

                    TextInput {
                        id: pw
                        anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                        verticalAlignment: TextInput.AlignVCenter
                        echoMode: TextInput.Password
                        color: Theme.fg
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize
                        clip: true
                        focus: entry.open
                        onVisibleChanged: if (visible) { text = ""; forceActiveFocus(); }
                        onAccepted: connectBtn.clicked()
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: pw.text === ""
                            text: "Password"
                            color: Theme.dim
                            font: pw.font
                        }
                    }
                }
                TextButton {
                    id: connectBtn
                    text: "Connect"
                    primary: true
                    onClicked: {
                        if (pw.text === "") return;
                        entry.net.connectWithPsk(pw.text);
                        root.expanded = null;
                    }
                }
            }
        }
    }

    Text {
        visible: root.error !== ""
        Layout.fillWidth: true
        Layout.topMargin: 6
        text: root.error
        wrapMode: Text.Wrap
        color: Theme.urgent
        font.family: Theme.font
        font.pixelSize: Theme.fontSize - 1
    }
}
