# AGENTS.md: reproducing this desktop

Guide for an agent (or person) recreating this rice on another Linux machine. The README shows what
it looks like; this file says how it's built, how to set it up, how to check it works, and what went
wrong the first time so you don't repeat it.

## Target

A Hyprland session next to the distro's existing desktop (GNOME here), shell drawn entirely by
Quickshell: floating bar, Control Center with tabs, Wi-Fi/Bluetooth pickers, launcher, macOS-style
dock, notifications, volume pop-up, lock screen and idle. 12 colour themes (Catppuccin, Tokyo Night,
Nord, Gruvbox, Rosé Pine, Dracula, Everforest, Kanagawa). Optional liquid glass
via the hyprglass Hyprland plugin. Screenshots: `docs/screenshots/`.

Built on (versions matter, see Gotchas):

| Piece | Version | Source on Fedora 44 |
|---|---|---|
| Hyprland | 0.57.2, **Lua config** (`hyprland.lua`) | COPR `sdegler/hyprland` |
| Quickshell | 0.3.2 | COPR `errornointernet/quickshell` |
| hyprlock / hypridle | 0.9.7 / 0.1.8 | COPR `sdegler/hyprland` |
| hyprglass (optional) | 1.2.0, built for Hyprland 0.57.2 | GitHub release `hyprnux/hyprglass` |
| GPU | NVIDIA proprietary 620 (GTX 1660 SUPER) + AMD iGPU | RPM Fusion |

Hyprland older than 0.55 uses `hyprland.conf` (hyprlang) and will not read this config. Quickshell
older than 0.3 lacks the `Quickshell.Networking` module the Network tab and pickers use.

## Setup on a new machine

1. **Packages.** Fedora: see README → Requirements. Other distros need the same set: `hyprland`
   (≥ 0.55), `xdg-desktop-portal-hyprland`, `hyprpolkitagent`, `hyprlock`, `hypridle`,
   `hyprlauncher` (fallback launcher only), `quickshell` (≥ 0.3), plus `kitty`, `nautilus`,
   `grim`, `slurp`, `wl-clipboard`, `satty`, `jq` (screenshots), Adwaita icon theme and the Adwaita
   Sans font. Package names vary; on Arch most are
   in the official repos or AUR.
2. **Configs.** `./install.sh` (copies `config/` into `~/.config`, backs up existing files, copies
   the wallpaper to `~/Pictures/Wallpapers`).
3. **Machine-specific edits** in `~/.config/hypr/hyprland.lua`:
   - The `DP-4` monitor block (mode `3840x2160@160`, scale 1.25). Replace with the target's output
     from `hyprctl monitors all`, or delete it; the generic `output = ""` rule covers the rest.
   - NVIDIA env vars (`LIBVA_DRIVER_NAME`, `__GLX_VENDOR_LIBRARY_NAME`, `NVD_BACKEND`). Remove them
     on AMD/Intel-only machines.
   - `hl.exec_cmd("/usr/libexec/hyprpolkitagent")`: Fedora's path. Elsewhere find it with the
     package manager (e.g. `/usr/lib/hyprpolkitagent/hyprpolkitagent` on Arch).
   - `STEAM_FORCE_DESKTOPUI_SCALING` (1.25): set it to the target's monitor scale.
4. **Liquid glass (optional).** README → Liquid glass. The `.so` must match `hyprctl version`
   exactly; link it as `~/.local/share/hyprland/plugins/hyprglass.so`. Without it the shell uses
   solid panels automatically.
5. Log out, pick **Hyprland** at the login screen.

## How it fits together

```
settings.json ──> Settings.qml ──> Theme.qml ──> every QML component (colours, radii, timings)
                       │
                       └──> ~/.config/hypr/look.lua ──(dofile)──> hyprland.lua
                             (accent borders, glass on/off + strength, bar radius, animations)
                             written only when its text changes, then `hyprctl reload`
```

Themes live in `quickshell/themes.js`: each has the role colours Theme.qml reads (`crust` bar,
`mantle` panels, `base` cards, `surface0/1`, `overlay0/2`, `subtext0/1`, `text`, `red/green/yellow`)
plus its own accent list and default accent. Catppuccin's four come from the generated
`palettes.js`. To add a theme, add one `add(id, {...})` block; nothing else needs to change.

- **`hyprland.lua`**: monitor; `hl.on("hyprland.start")` starts the session target, Quickshell
  (`qs`), the polkit agent and hypridle; `hl.on("hyprland.shutdown")` stops the session
  target; env vars; hyprglass load + per-layer glass rules; look values from `look.lua`; keys.
- **`systemd/user/hyprland-session.target`**: binds `graphical-session.target` so
  `xdg-desktop-portal` (file pickers, screen share, dark-mode reporting) can start.
- **Quickshell layout**: `shell.qml` instantiates windows. Root `*.qml` files are windows and
  singletons (`Theme`, `Settings`, `Panels`, `AudioService`, `NetworkService`, `MediaService`,
  `NotificationService`). `ui/` holds widgets, `cc/` the Control Center tabs. Imports use
  `import qs` / `import qs.ui` / `import qs.cc`.
- **Panels state** lives in `Panels.qml`: which Control Center tab is open, which picker is open,
  and the screen x of the bar item that opened it (panels grow out of that point).
- **IPC** (`qs ipc call <target> <fn> [arg]`):
  - `launcher toggle|open|close`
  - `controlcenter toggle|open <tab>` and `controlcenter close`, where `<tab>` is one of
    `home audio network bluetooth media calendar notifications settings`
  - `picker toggle wifi|bluetooth` and `picker close`

  Super+Space runs `qs ipc call launcher toggle`.
- **Layer namespaces** (`hyprctl layers`): `quickshell-bar`, `-wallpaper`, `-controlcenter`,
  `-picker`, `-launcher`, `-notifications`, `-osd`, `-dock`. hyprglass rules match these, so every
  surface needs its own namespace.
- **Dock**: slots are a stable `ListModel` synced from a computed list, so delegates survive
  reorders and drags. Magnification is computed from the resting layout (no feedback). Changing
  `dockPosition` recreates the window (`Variants` keyed on the edge) because layer-shell anchors are
  set at creation.

## Verifying (run these; don't assume)

```bash
Hyprland --verify-config -c ~/.config/hypr/hyprland.lua   # parse check without starting
export HYPRLAND_INSTANCE_SIGNATURE=$(basename $(dirname $(ls -t $XDG_RUNTIME_DIR/hypr/*/hyprland.log | head -1)))
hyprctl configerrors                 # empty = good
hyprctl layers | grep namespace      # the quickshell-* surfaces above
hyprctl hyprglass status             # "active", "version check: match" when glass is installed
systemctl --user is-active graphical-session.target xdg-desktop-portal   # both active in Hyprland

export WAYLAND_DISPLAY=wayland-1     # the Hyprland socket; qs only lists instances on this display
qs list                              # running instance id
cat /run/user/$UID/quickshell/by-id/<id>/log.log   # QML errors/warnings land here
qs ipc call controlcenter open settings
```

Quickshell hot-reloads on save; read the newest `Reloading configuration` → `Configuration Loaded`
block of the log after every edit. A failed reload keeps the old config running, so a broken file
can look fine until the next start.

Screenshots for visual checks: the `org.freedesktop.portal.Screenshot` portal (non-interactive)
works once the session target is up; `grim` isn't needed.

## Gotchas (each cost a debugging round)

**Hyprland / session**
- 0.55+ config is Lua. Online examples in hyprlang syntax don't apply. Dispatch from the shell
  with `hyprctl dispatch 'hl.dsp.exit()'` style expressions.
- Lua `require` caches modules across reloads; use `dofile` for generated files (`look.lua`), in
  `pcall` since a missing file raises. `io.open` is available (used to load the plugin only if
  present).
- Fedora's COPR installs `hyprland-session.target` to `/usr/lib64/systemd/user`, which systemd
  doesn't read. Without a session target, `xdg-desktop-portal` refuses to start
  (`Requisite=graphical-session.target`). Hence the target in this repo.
- User services can outlive the session (lingering). Stop the session target on
  `hyprland.shutdown`, set env vars with `hl.env` only (not `environment.d`), and start
  `hyprpolkitagent` from Hyprland rather than enabling its unit. Otherwise GNOME sessions inherit
  Hyprland state.
- Fractional scaling blurs X11 apps (Steam): Hyprland draws them at 100% and stretches them.
  `xwayland:force_zero_scaling = true` makes them render at full resolution; each app then scales
  itself (`STEAM_FORCE_DESKTOPUI_SCALING` for Steam). Check with `hyprctl clients` (`xwayland: 1`).
- Flameshot's interactive capture doesn't work under Hyprland here; screenshots use
  `hypr/scripts/screenshot.sh` (grim + slurp + Satty) bound to Print.
- `cursor:no_warps = true`: otherwise focusing a window (dock click, other workspace) warps the
  pointer to its centre.
- `binds:drag_center_window = false` and `binds:drag_threshold = 10`: otherwise dragging a tiled
  window by its titlebar snaps its centre to the cursor. A dragged *tiled* window always returns to
  the layout on release; only floating windows (Super+V) stay where dropped.
- Monitor default was `preferred` = 60 Hz at scale 1 on a 160 Hz 4K panel; set mode and scale
  explicitly.

**Quickshell / QML**
- Set `QS_ICON_THEME` (here `Adwaita`); with no desktop to inherit from, theme icons don't resolve.
- Adwaita `-symbolic` icons are black. `ui/SymbolIcon.qml` recolours them with a `MultiEffect`
  alpha mask.
- A property named `on` + capital letter (`onAccent`) is parsed as a signal handler. Use names
  like `accentInk`.
- QML's JS engine lacks `??=`.
- `HoverHandler.point` changes don't emit `pointChanged`; bind `point.position` directly.
- Changing an `IconImage`'s size re-requests the image (async), which flickers during
  magnification. Load it at max size and animate `scale`. Same for popups: don't move a
  `PopupWindow` anchor every frame.
- `DesktopEntries.applications` and `ToplevelManager.toplevels` stay empty in a test script until
  something binds them *and* a window exists.
- A `ColumnLayout`'s max width comes from its children; set `Layout.fillWidth` on child `Text`s or
  rows won't stretch (right-aligned toggles end up mid-row). A sidebar column whose children fill
  width grabs space too: give it `Layout.fillWidth: false` + fixed width.
- `Translate` (and other transforms) have no `parent`; reference an `id`.
- `stage: stage` inside a child whose own property is `stage` binds to itself. Use a distinct id.
- `JsonAdapter`: keys missing from `settings.json` keep their current in-memory value; they don't
  reset to defaults.
- `Networking` device list fills a moment after start; `WifiNetwork.signalStrength` is 0..1.
- Qt can't render GNOME's SVG wallpapers (mesh gradients); JPEG/PNG/JXL are fine (JXL needs
  `kimageformats`).

**Testing limits**
- `hyprctl dispatch 'hl.dsp.cursor.move(...)'` moves the pointer without sending motion events to
  clients, so hover/magnification can't be exercised from a script; neither can clicks. Ask the
  user to check those.
- The portal writes screenshots under `/run/user/...`; move them with `shutil.move`, not
  `os.rename` (different filesystem).

**hyprglass**
- Must match the exact Hyprland build; it pauses itself (no crash) on mismatch.
- Glass is drawn behind visible content (`mask_mode = "contour"`), so panels need a translucent
  fill. Too transparent is unreadable over a busy wallpaper: current dark-flavour fills are bar
  0.55, panels 0.68, cards white 0.07 (`Theme.qml`). Latte needs denser fills.
- `Theme.qml` turns glass on only if `hyprctl plugin list` mentions hyprglass *and* Settings says
  glass, so a missing plugin degrades to solid panels instead of see-through ones.

## Keeping the repo clean

- `./sync.sh` copies live configs back and refuses to finish if any file contains `$HOME`
  (username leak).
- Not tracked: `look.lua` (generated), plugin `.so` files, backups.
- Screenshots blur Wi-Fi network names, Bluetooth device names and the user's name. Take them on
  an empty workspace so no window contents show.
