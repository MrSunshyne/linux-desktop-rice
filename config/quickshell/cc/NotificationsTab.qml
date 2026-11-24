// Notification history with Do Not Disturb and Clear all.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs
import qs.ui

ColumnLayout {
    id: root
    spacing: 10

    SystemClock { id: clock; precision: SystemClock.Minutes }

    Card {
        Layout.fillWidth: true
        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            SymbolIcon {
                icon: NotificationService.dnd ? "notifications-disabled-symbolic" : "preferences-system-notifications-symbolic"
                size: 18
                color: NotificationService.dnd ? Theme.accent : Theme.fg
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                Text {
                    Layout.fillWidth: true
                    text: "Do Not Disturb"
                    color: Theme.fg
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                }
                Text {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    text: "Only critical notifications pop up. Everything is still kept here."
                    color: Theme.muted
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 2
                }
            }
            Toggle {
                checked: NotificationService.dnd
                onToggled: NotificationService.dnd = !NotificationService.dnd
            }
        }
    }

    SectionTitle {
        text: "HISTORY"
        TextButton {
            visible: NotificationService.history.count > 0
            text: "Clear all"
            onClicked: NotificationService.clear()
        }
    }

    Card {
        Layout.fillWidth: true
        visible: NotificationService.history.count === 0
        padding: 28
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 8
            SymbolIcon { Layout.alignment: Qt.AlignHCenter; icon: "preferences-system-notifications-symbolic"; size: 32; color: Theme.dim }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "No notifications"
                color: Theme.muted
                font.family: Theme.font
                font.pixelSize: Theme.fontSize + 1
            }
        }
    }

    ListView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: NotificationService.history.count > 0
        clip: true
        spacing: 8
        boundsBehavior: Flickable.StopAtBounds
        model: NotificationService.history

        delegate: Rectangle {
            id: item
            required property int index
            required property string appName
            required property string appIcon
            required property string summary
            required property string body
            required property double time

            width: ListView.view.width
            implicitHeight: content.implicitHeight + 24
            radius: Theme.radiusCard
            color: hover.hovered ? Theme.cardHover : Theme.card
            border.width: 1
            border.color: Theme.border
            Behavior on color { ColorAnimation { duration: Theme.anim } }

            HoverHandler { id: hover }

            RowLayout {
                id: content
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                spacing: 12

                IconImage {
                    Layout.alignment: Qt.AlignTop
                    source: NotificationService.iconSource(item.appIcon) || Quickshell.iconPath("preferences-system-notifications", true)
                    implicitSize: 32
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            Layout.fillWidth: true
                            text: item.appName || "Notification"
                            elide: Text.ElideRight
                            color: Theme.muted
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 2
                        }
                        Text {
                            text: NotificationService.ago(item.time, clock.date.getTime())
                            color: Theme.dim
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 2
                        }
                    }
                    Text {
                        Layout.fillWidth: true
                        text: item.summary
                        elide: Text.ElideRight
                        color: Theme.fg
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize
                        font.weight: Font.DemiBold
                    }
                    Text {
                        Layout.fillWidth: true
                        visible: text !== ""
                        text: item.body
                        wrapMode: Text.Wrap
                        maximumLineCount: 3
                        elide: Text.ElideRight
                        color: Theme.muted
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize - 1
                    }
                }
                IconButton {
                    Layout.alignment: Qt.AlignTop
                    size: 26
                    icon: "window-close-symbolic"
                    ink: Theme.dim
                    opacity: hover.hovered ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: Theme.anim } }
                    onClicked: NotificationService.remove(item.index)
                }
            }
        }
    }
}
