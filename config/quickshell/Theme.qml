pragma Singleton
// Colours, sizes, fonts and timings shared by every component.
// Driven by Settings.qml (Control Center → Settings); palette data in palettes.js.
import QtQuick
import Quickshell
import Quickshell.Io
import "palettes.js" as Palettes

Singleton {
    id: theme

    // ---- Palette (Catppuccin flavour + accent) ------------------------------
    readonly property var flavour: Palettes.flavours[Settings.flavour] ?? Palettes.flavours.mocha
    readonly property var c: flavour.colors
    readonly property bool dark: flavour.dark

    readonly property color crust: c.crust
    readonly property color mantle: c.mantle
    readonly property color base: c.base
    readonly property color surface0: c.surface0
    readonly property color surface1: c.surface1
    readonly property color overlay0: c.overlay0
    readonly property color subtext: c.subtext0
    readonly property color text: c.text
    readonly property color red: c.red
    readonly property color green: c.green
    readonly property color yellow: c.yellow

    // ---- Material ------------------------------------------------------------
    // Glass needs the hyprglass Hyprland plugin (config in hyprland.lua). When it
    // is loaded and Settings.material is "glass", surfaces turn translucent and
    // the plugin draws blur, refraction and highlights behind them.
    property bool glassAvailable: false
    property Process glassProbe: Process {
        running: true
        command: ["hyprctl", "plugin", "list"]
        stdout: StdioCollector { onStreamFinished: theme.glassAvailable = text.includes("hyprglass") }
    }
    readonly property bool glass: glassAvailable && Settings.material === "glass"

    // Highlights are white on dark flavours, black on Latte.
    readonly property color sheen: dark ? "#ffffff" : "#000000"

    // ---- Roles used by components -------------------------------------------
    // Glass fills are dense enough to stay readable over bright, busy wallpapers;
    // the plugin's blur and refraction show through around them. Light glass over
    // dark windows washes out, so Latte keeps more of its own colour.
    readonly property color bg: glass ? Qt.alpha(crust, dark ? 0.55 : 0.7) : Qt.alpha(crust, 0.92)  // bar
    readonly property color panel: glass ? Qt.alpha(mantle, dark ? 0.68 : 0.8) : mantle             // panels, popups
    readonly property color card: glass ? Qt.alpha(sheen, dark ? 0.07 : 0.05) : base                // cards, capsules
    readonly property color cardHover: glass ? Qt.alpha(sheen, dark ? 0.13 : 0.09) : surface0
    readonly property color border: glass ? Qt.alpha(sheen, dark ? 0.13 : 0.1) : Qt.alpha(surface1, 0.6)
    readonly property color backdrop: glass ? "transparent" : Qt.alpha(crust, dark ? 0.35 : 0.2)   // behind open panels

    readonly property color fg: text
    readonly property color muted: dark ? subtext : c.subtext1   // secondary text; darker on Latte
    readonly property color dim: dark ? overlay0 : c.overlay2    // hints, disabled
    readonly property color accent: c[Settings.accent] ?? c.sapphire
    readonly property color accentInk: dark ? crust : base        // text/icons on accent fills
    readonly property color accentSoft: Qt.alpha(accent, 0.16)
    readonly property color urgent: red
    readonly property color good: green

    readonly property string font: "Adwaita Sans"
    readonly property int fontSize: 13

    // ---- Shape -----------------------------------------------------------------
    readonly property int barHeight: Settings.barHeight
    readonly property int barGap: Settings.barFloating ? 8 : 0           // space to the screen edges
    readonly property int barRadius: Settings.barFloating ? Math.min(Settings.roundness, Math.floor(barHeight / 2)) : 0
    readonly property int radius: Settings.roundness                     // panels
    readonly property int radiusCard: Math.round(Settings.roundness * 0.75)
    readonly property int radiusSmall: Math.round(Settings.roundness * 0.5)

    // ---- Motion ----------------------------------------------------------------
    readonly property real speed: ({ off: 0, fast: 0.6, normal: 1, relaxed: 1.5 })[Settings.motion] ?? 1
    function dur(ms) { return Math.round(ms * speed); }
    readonly property int anim: dur(200)        // colour/opacity transitions

    readonly property string wallpaper: "file://" + Settings.wallpaperPath
}
