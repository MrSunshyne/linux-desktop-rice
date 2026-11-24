// Wired status and the Wi-Fi network list (ui/WifiList.qml, shared with the
// bar's Wi-Fi picker).
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking
import qs
import qs.ui

Flickable {
    id: root
    contentHeight: column.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    readonly property var wired: NetworkService.wiredDevice

    ColumnLayout {
        id: column
        width: root.width
        spacing: 10

        SectionTitle { text: "ETHERNET"; visible: root.wired !== null }
        Card {
            Layout.fillWidth: true
            visible: root.wired !== null
            ListItem {
                interactive: false
                icon: "network-wired-symbolic"
                title: root.wired?.name ?? ""
                subtitle: !root.wired ? ""
                    : root.wired.connected ? "Connected" + (root.wired.linkSpeed > 0 ? " · " + root.wired.linkSpeed + " Mb/s" : "")
                    : root.wired.hasLink ? "Cable plugged in, not connected" : "Cable unplugged"
                active: root.wired?.connected ?? false
            }
        }

        SectionTitle {
            text: "WI-FI"
            visible: NetworkService.wifiDevice !== null
            Toggle {
                checked: Networking.wifiEnabled
                onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
            }
        }
        Card {
            Layout.fillWidth: true
            visible: NetworkService.wifiDevice !== null
            WifiList {}
        }

        TextButton {
            Layout.topMargin: 4
            text: "Network settings…"
            onClicked: {
                Panels.close();
                Quickshell.execDetached(["env", "XDG_CURRENT_DESKTOP=GNOME", "gnome-control-center", "network"]);
            }
        }
    }
}
