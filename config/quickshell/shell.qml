// Entry point. Quickshell (`qs`) loads this file and hot-reloads on save.
// Started from ~/.config/hypr/hyprland.lua; only runs inside Hyprland.
//
// Layout:  *.qml here      windows and shared singletons (Theme, Panels, *Service)
//          ui/             reusable widgets (Card, Slider, Toggle, ListItem, ...)
//          cc/             Control Center tabs
import Quickshell

ShellRoot {
    // One wallpaper and one bar per monitor.
    Variants {
        model: Quickshell.screens
        Wallpaper {}
    }
    Variants {
        model: Quickshell.screens
        Bar {}
    }

    ControlCenter {}
    Dock {}
    Launcher {}
    BarPicker {}
    NotificationPopups {}
    VolumeOsd {}
}
