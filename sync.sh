#!/usr/bin/env bash
# Pull the live configs from ~/.config back into ./config, then show what changed.
# Review `git diff` before committing: nothing personal should end up here.
set -euo pipefail

repo="$(cd "$(dirname "$0")" && pwd)"
src="${XDG_CONFIG_HOME:-$HOME/.config}"

mkdir -p "$repo/config/hypr" "$repo/config/systemd/user"
cp "$src/hypr/hyprland.lua" "$src/hypr/hypridle.conf" "$src/hypr/hyprlock.conf" "$repo/config/hypr/"
rm -rf "$repo/config/quickshell"
cp -r "$src/quickshell" "$repo/config/quickshell"
cp "$src/systemd/user/hyprland-session.target" "$repo/config/systemd/user/"

# Absolute home paths would leak the username.
if grep -rnI "$HOME" "$repo/config"; then
    echo "!! Found '$HOME' above. Replace it with ~ or \$HOME before committing." >&2
    exit 1
fi

git -C "$repo" status --short
