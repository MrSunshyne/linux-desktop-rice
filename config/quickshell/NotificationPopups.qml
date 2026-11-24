// Notification pop-ups, top-right under the bar. Click to dismiss.
// Critical ones stay until clicked; others use the app's timeout or 6 s.
// The daemon and history live in NotificationService.qml.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Widgets
import Quickshell.Wayland
import qs.ui

PanelWindow {
    WlrLayershell.namespace: "quickshell-notifications"
    readonly property var popups: NotificationService.server.trackedNotifications

    visible: popups.values.length > 0
    anchors { top: true; right: true }
    // Sit left of the Control Center while it's open (800 wide + margins).
    margins { top: 8; right: Panels.open ? 816 : 8 }
    exclusiveZone: 0
    implicitWidth: 380
    implicitHeight: column.implicitHeight
    color: "transparent"

    Column {
        id: column
        width: parent.width
        spacing: 8

        Repeater {
            model: popups
            delegate: Rectangle {
                id: popup
                required property var modelData
                readonly property bool critical: modelData.urgency === NotificationUrgency.Critical
                width: column.width
                height: content.implicitHeight + 24
                radius: Theme.radiusCard
                color: Theme.panel
                border.width: 1
                border.color: critical ? Theme.urgent : Theme.border

                Timer {
                    running: !popup.critical
                    interval: popup.modelData.expireTimeout > 0 ? popup.modelData.expireTimeout : 6000
                    onTriggered: popup.modelData.expire()
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: popup.modelData.dismiss()
                }

                RowLayout {
                    id: content
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                    spacing: 12

                    IconImage {
                        Layout.alignment: Qt.AlignTop
                        visible: source != ""
                        source: NotificationService.iconSource(popup.modelData.image || popup.modelData.appIcon)
                        implicitSize: 36
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            Layout.fillWidth: true
                            visible: text !== ""
                            text: popup.modelData.appName
                            elide: Text.ElideRight
                            color: Theme.muted
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 2
                        }
                        Text {
                            Layout.fillWidth: true
                            text: popup.modelData.summary
                            elide: Text.ElideRight
                            color: Theme.fg
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize
                            font.weight: Font.DemiBold
                        }
                        Text {
                            Layout.fillWidth: true
                            visible: text !== ""
                            text: popup.modelData.body
                            wrapMode: Text.Wrap
                            maximumLineCount: 4
                            elide: Text.ElideRight
                            color: Theme.muted
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 1
                        }
                        RowLayout {
                            Layout.topMargin: 6
                            visible: popup.modelData.actions.length > 0
                            spacing: 6
                            Repeater {
                                model: popup.modelData.actions
                                delegate: TextButton {
                                    required property var modelData
                                    text: modelData.text
                                    onClicked: modelData.invoke()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
