// Appearance settings. Everything applies live and is saved by Settings.qml.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs
import qs.ui
import "../themes.js" as Themes

Flickable {
    id: root
    contentHeight: column.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    component Label: Text {
        Layout.fillWidth: true
        color: Theme.fg
        font.family: Theme.font
        font.pixelSize: Theme.fontSize
    }
    component Hint: Text {
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        color: Theme.dim
        font.family: Theme.font
        font.pixelSize: Theme.fontSize - 2
    }

    // Wallpapers: your folder first, then Fedora's and GNOME's own.
    readonly property string userWallpapers: Settings.home + "/Pictures/Wallpapers"
    property var wallpapers: []
    Process {
        running: true
        // SVGs are left out: GNOME's use mesh gradients that Qt can't draw.
        command: ["sh", "-c", 'mkdir -p "$1"; find "$1" /usr/share/backgrounds/f44 /usr/share/backgrounds/gnome -maxdepth 2 -type f \\( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.jxl" \\) 2>/dev/null', "sh", root.userWallpapers]
        stdout: StdioCollector { onStreamFinished: root.wallpapers = text.split("\n").filter(s => s !== "") }
    }

    ColumnLayout {
        id: column
        width: root.width
        spacing: 10

        // ---- Theme --------------------------------------------------------
        SectionTitle { text: "THEME" }
        Card {
            Layout.fillWidth: true
            spacing: 12

            Label { text: "Theme" }
            GridLayout {
                Layout.fillWidth: true
                columns: 4
                columnSpacing: 8
                rowSpacing: 8
                Repeater {
                    model: Themes.order
                    delegate: Rectangle {
                        required property string modelData
                        readonly property var f: Themes.themes[modelData]
                        readonly property bool selected: Settings.flavour === modelData
                        Layout.fillWidth: true
                        implicitHeight: 72
                        radius: Theme.radiusSmall
                        color: f.colors.base
                        border.width: selected ? 2 : 1
                        border.color: selected ? Theme.accent : Theme.border

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 6
                            Row {
                                Layout.alignment: Qt.AlignHCenter
                                spacing: 4
                                Repeater {
                                    model: ["text", Themes.accentOf(f, Settings.accent), "surface1", "crust"]
                                    delegate: Rectangle {
                                        required property string modelData
                                        width: 12; height: 12; radius: 6
                                        color: f.colors[modelData]
                                    }
                                }
                            }
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: f.name
                                color: f.colors.text
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize - 1
                                font.weight: selected ? Font.DemiBold : Font.Normal
                            }
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                visible: f.family === "Catppuccin"
                                text: "Catppuccin"
                                color: f.colors.subtext0
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize - 3
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            // Keep the accent if the new theme has it, else use the theme's own default.
                            onClicked: {
                                Settings.flavour = modelData;
                                Settings.accent = Themes.accentOf(f, Settings.accent);
                            }
                        }
                    }
                }
            }
            Hint { text: "Latte and Rosé Pine Dawn are light. Only the shell and window borders change; apps keep following GNOME's dark/light setting." }

            Label { text: "Accent"; Layout.topMargin: 4 }
            Flow {
                Layout.fillWidth: true
                spacing: 8
                Repeater {
                    model: Theme.flavour.accents
                    delegate: Rectangle {
                        required property string modelData
                        readonly property bool selected: Theme.accentName === modelData
                        width: 30; height: 30; radius: 15
                        color: "transparent"
                        border.width: 2
                        border.color: selected ? Theme.fg : "transparent"
                        Rectangle {
                            anchors.centerIn: parent
                            width: 22; height: 22; radius: 11
                            color: Theme.flavour.colors[modelData] ?? "transparent"   // briefly unset while switching themes
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Settings.accent = modelData
                        }
                    }
                }
            }
        }

        // ---- Material -----------------------------------------------------
        SectionTitle { text: "MATERIAL" }
        Card {
            Layout.fillWidth: true
            spacing: 14

            Segmented {
                options: [{ value: "glass", label: "Liquid glass" }, { value: "solid", label: "Solid" }]
                current: Settings.material
                disabled: Theme.glassAvailable ? [] : ["glass"]
                onPicked: v => Settings.material = v
            }
            Hint {
                visible: !Theme.glassAvailable
                text: "Liquid glass needs the hyprglass plugin, which isn't loaded (see the LIQUID GLASS section in ~/.config/hypr/hyprland.lua)."
            }

            SettingSlider {
                visible: Theme.glass
                label: "Frost"
                valueText: Settings.frost.toFixed(1)
                from: 0.4; to: 3.0; step: 0.1
                value: Settings.frost
                onMoved: v => Settings.frost = v
            }
            SettingSlider {
                visible: Theme.glass
                label: "Refraction"
                valueText: Settings.refraction.toFixed(1)
                from: 0; to: 3.0; step: 0.1
                value: Settings.refraction
                onMoved: v => Settings.refraction = v
            }
            SettingSlider {
                visible: Theme.glass
                label: "Tint"
                valueText: Math.round(Settings.tint * 100) + "%"
                from: 0; to: 0.8; step: 0.05
                value: Settings.tint
                onMoved: v => Settings.tint = v
            }
        }

        // ---- Bar ----------------------------------------------------------
        SectionTitle { text: "BAR" }
        Card {
            Layout.fillWidth: true
            spacing: 14

            Segmented {
                options: [{ value: true, label: "Floating" }, { value: false, label: "Edge to edge" }]
                current: Settings.barFloating
                onPicked: v => Settings.barFloating = v
            }
            SettingSlider {
                label: "Height"
                valueText: Settings.barHeight + " px"
                from: 28; to: 44; step: 2
                value: Settings.barHeight
                onMoved: v => Settings.barHeight = v
            }
            SettingSlider {
                label: "Corner roundness"
                valueText: Settings.roundness + " px"
                from: 0; to: 24; step: 1
                value: Settings.roundness
                onMoved: v => Settings.roundness = v
            }
            Hint { text: "Roundness also applies to panels, cards and buttons." }
        }

        // ---- Dock ---------------------------------------------------------
        SectionTitle {
            text: "DOCK"
            Toggle {
                checked: Settings.dockEnabled
                onToggled: Settings.dockEnabled = !Settings.dockEnabled
            }
        }
        Card {
            Layout.fillWidth: true
            visible: Settings.dockEnabled
            spacing: 14

            RowLayout {
                Layout.fillWidth: true
                Label { text: "Auto-hide" }
                Toggle {
                    checked: Settings.dockAutohide
                    onToggled: Settings.dockAutohide = !Settings.dockAutohide
                }
            }
            Hint { text: "Hidden until the pointer touches the dock's screen edge. Off: windows tile beside the dock." }
            Segmented {
                options: [{ value: "left", label: "Left" }, { value: "bottom", label: "Bottom" }, { value: "right", label: "Right" }]
                current: Settings.dockPosition
                onPicked: v => Settings.dockPosition = v
            }
            SettingSlider {
                label: "Icon size"
                valueText: Settings.dockIconSize + " px"
                from: 36; to: 72; step: 4
                value: Settings.dockIconSize
                onMoved: v => Settings.dockIconSize = v
            }
            SettingSlider {
                label: "Magnification"
                valueText: Settings.dockMagnification <= 1.001 ? "Off" : Math.round(Settings.dockMagnification * 100) + "%"
                from: 1.0; to: 2.0; step: 0.1
                value: Settings.dockMagnification
                onMoved: v => Settings.dockMagnification = v
            }
            Hint { text: "Drag icons to reorder; drag a running app in to keep it, or a kept app up and out to remove it. Right-click for more." }
        }

        // ---- Motion -------------------------------------------------------
        SectionTitle { text: "MOTION" }
        Card {
            Layout.fillWidth: true
            Segmented {
                options: [
                    { value: "off", label: "Off" },
                    { value: "fast", label: "Fast" },
                    { value: "normal", label: "Normal" },
                    { value: "relaxed", label: "Relaxed" },
                ]
                current: Settings.motion
                onPicked: v => Settings.motion = v
            }
            Hint { text: "Shell animations. Off also turns off Hyprland's window animations." }
        }

        // ---- Wallpaper ----------------------------------------------------
        SectionTitle {
            text: "WALLPAPER"
            TextButton {
                text: "Open folder"
                onClicked: Quickshell.execDetached(["nautilus", root.userWallpapers])
            }
        }
        Card {
            Layout.fillWidth: true
            Hint { text: "Add your own pictures to ~/Pictures/Wallpapers. Also used by the lock screen." }

            GridLayout {
                Layout.fillWidth: true
                columns: 4
                rowSpacing: 8
                columnSpacing: 8

                Repeater {
                    // "" = the picture GNOME uses
                    model: [""].concat(root.wallpapers)
                    delegate: Rectangle {
                        required property string modelData
                        readonly property bool selected: Settings.wallpaper === modelData
                        Layout.fillWidth: true
                        implicitHeight: width * 9 / 16
                        radius: Theme.radiusSmall
                        color: Theme.card
                        border.width: selected ? 2 : 0
                        border.color: Theme.accent
                        clip: true

                        Image {
                            anchors { fill: parent; margins: selected ? 3 : 0 }
                            source: "file://" + (modelData || Settings.gnomeWallpaper)
                            sourceSize.width: 320
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true
                        }
                        Rectangle {
                            visible: modelData === ""
                            anchors { left: parent.left; bottom: parent.bottom; margins: 6 }
                            implicitWidth: tag.implicitWidth + 10; implicitHeight: 18
                            radius: 9
                            color: Qt.alpha(Theme.crust, 0.7)
                            Text {
                                id: tag
                                anchors.centerIn: parent
                                text: "GNOME's"
                                color: Theme.text
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize - 3
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Settings.wallpaper = modelData
                        }
                    }
                }
            }
        }
    }
}
