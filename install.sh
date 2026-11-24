#!/usr/bin/env bash
# Copy the configs in ./config into ~/.config.
# Anything already there is moved aside to <name>.bak-<timestamp> first.
set -euo pipefail

src="$(cd "$(dirname "$0")" && pwd)/config"
dest="${XDG_CONFIG_HOME:-$HOME/.config}"
stamp="$(date +%Y%m%d-%H%M%S)"

install_path() {   # $1 = path relative to config/
    local from="$src/$1" to="$dest/$1"
    if [ -e "$to" ] || [ -L "$to" ]; then
        mv "$to" "$to.bak-$stamp"
        echo "backed up  $to -> $to.bak-$stamp"
    fi
    mkdir -p "$(dirname "$to")"
    cp -r "$from" "$to"
    echo "installed  $to"
}

install_path hypr/hyprland.lua
install_path hypr/hypridle.conf
install_path hypr/hyprlock.conf
install_path quickshell
install_path systemd/user/hyprland-session.target

systemctl --user daemon-reload 2>/dev/null || true

cat <<'EOF'

Done. Next:
  - Adjust the monitor block near the top of ~/.config/hypr/hyprland.lua
    (output name, mode, scale) for your screen.
  - Optional liquid glass: see "Liquid glass" in README.md.
  - Log out and pick "Hyprland" on the login screen.
EOF
