// One card per MPRIS player: artwork, track, progress, controls.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import qs
import qs.ui

Flickable {
    id: root
    contentHeight: column.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    ColumnLayout {
        id: column
        width: root.width
        spacing: 12

        Card {
            Layout.fillWidth: true
            visible: MediaService.players.length === 0
            padding: 28
            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 8
                SymbolIcon { Layout.alignment: Qt.AlignHCenter; icon: "multimedia-player-symbolic"; size: 32; color: Theme.dim }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Nothing playing"
                    color: Theme.muted
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize + 1
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Players such as Spotify, browsers and mpv show up here."
                    color: Theme.dim
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 1
                }
            }
        }

        Repeater {
            model: MediaService.players
            delegate: Card {
                id: card
                required property var modelData
                readonly property var player: modelData
                Layout.fillWidth: true
                padding: 16

                // MPRIS doesn't push position updates; poll while playing.
                Timer {
                    running: card.player.isPlaying && card.player.positionSupported
                    interval: 1000
                    repeat: true
                    onTriggered: card.player.positionChanged()
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 16

                    Rectangle {
                        implicitWidth: 96; implicitHeight: 96
                        radius: Theme.radiusSmall
                        color: Theme.surface0
                        clip: true
                        Image {
                            anchors.fill: parent
                            source: card.player.trackArtUrl
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            visible: status === Image.Ready
                        }
                        SymbolIcon {
                            anchors.centerIn: parent
                            visible: card.player.trackArtUrl === ""
                            icon: "multimedia-player-symbolic"
                            size: 32
                            color: Theme.dim
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        Text {
                            Layout.fillWidth: true
                            text: card.player.identity
                            elide: Text.ElideRight
                            color: Theme.accent
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 2
                            font.weight: Font.DemiBold
                        }
                        Text {
                            Layout.fillWidth: true
                            text: card.player.trackTitle || "Unknown track"
                            elide: Text.ElideRight
                            color: Theme.fg
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize + 3
                            font.weight: Font.DemiBold
                        }
                        Text {
                            Layout.fillWidth: true
                            visible: text !== ""
                            text: [card.player.trackArtist, card.player.trackAlbum].filter(s => s).join(" · ")
                            elide: Text.ElideRight
                            color: Theme.muted
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 1
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.topMargin: 6
                            spacing: 10
                            visible: card.player.lengthSupported && card.player.length > 0
                            Text {
                                text: MediaService.formatTime(card.player.position)
                                color: Theme.dim
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize - 2
                            }
                            Slider {
                                Layout.fillWidth: true
                                implicitHeight: 6
                                value: card.player.length > 0 ? card.player.position / card.player.length : 0
                                onMoved: v => { if (card.player.positionSupported) card.player.position = v * card.player.length; }
                            }
                            Text {
                                text: MediaService.formatTime(card.player.length)
                                color: Theme.dim
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize - 2
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 14
                    IconButton {
                        icon: "media-skip-backward-symbolic"
                        opacity: card.player.canGoPrevious ? 1 : 0.4
                        onClicked: if (card.player.canGoPrevious) card.player.previous()
                    }
                    IconButton {
                        size: 46
                        checked: true
                        icon: card.player.isPlaying ? "media-playback-pause-symbolic" : "media-playback-start-symbolic"
                        onClicked: if (card.player.canTogglePlaying) card.player.togglePlaying()
                    }
                    IconButton {
                        icon: "media-skip-forward-symbolic"
                        opacity: card.player.canGoNext ? 1 : 0.4
                        onClicked: if (card.player.canGoNext) card.player.next()
                    }
                }
            }
        }
    }
}
