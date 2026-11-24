pragma Singleton
// NetworkManager state shared by the bar and the Network tab.
import QtQuick
import Quickshell
import Quickshell.Networking

Singleton {
    readonly property var devices: Networking.devices.values
    readonly property var wiredDevice: devices.find(d => d.type === DeviceType.Wired) ?? null
    readonly property var wifiDevice: devices.find(d => d.type === DeviceType.Wifi) ?? null

    readonly property bool wiredUp: wiredDevice?.connected ?? false
    readonly property var wifiNetwork: wifiDevice?.networks.values.find(n => n.connected) ?? null

    function signalIcon(s) {
        return s >= 0.75 ? "network-wireless-signal-excellent-symbolic"
             : s >= 0.5  ? "network-wireless-signal-good-symbolic"
             : s >= 0.25 ? "network-wireless-signal-ok-symbolic"
             : "network-wireless-signal-weak-symbolic";
    }

    // Wired wins over Wi-Fi when both are up.
    readonly property string icon: wiredUp ? "network-wired-symbolic"
        : wifiNetwork ? signalIcon(wifiNetwork.signalStrength)
        : !Networking.wifiEnabled ? "network-wireless-disabled-symbolic"
        : "network-offline-symbolic"
    readonly property string label: wiredUp ? "Wired" : wifiNetwork ? wifiNetwork.name : "Offline"
    readonly property bool online: wiredUp || wifiNetwork !== null
}
