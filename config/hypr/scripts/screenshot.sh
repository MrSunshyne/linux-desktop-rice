#!/usr/bin/env bash
# Screenshots with grim (capture), slurp (pick a region), wl-copy (clipboard)
# and Satty (annotate). Bound in hyprland.lua:
#   Print            region -> Satty (draw, then Enter copies, Ctrl+S saves)
#   Ctrl+Print       region -> clipboard + file, no editor
#   Shift+Print      whole screen (the one under the pointer) -> clipboard + file
#   Alt+Print        focused window -> clipboard + file
# Files go to ~/Pictures/Screenshots.
set -euo pipefail

dir="$HOME/Pictures/Screenshots"
mkdir -p "$dir"
file="$dir/Screenshot-$(date +%Y-%m-%d_%H-%M-%S).png"

# Copy and notify (the notification shows the picture).
finish() {
    wl-copy --type image/png < "$file"
    notify-send -a Screenshot -i "$file" "Screenshot copied" "Saved to ${file/#$HOME/\~}"
}

case "${1:-region-edit}" in
    region-edit)
        region=$(slurp -d) || exit 0            # Esc cancels
        grim -g "$region" - | satty --filename - \
            --output-filename "$dir/Screenshot-%Y-%m-%d_%H-%M-%S.png" \
            --copy-command wl-copy --early-exit
        ;;
    region)
        region=$(slurp -d) || exit 0
        grim -g "$region" "$file" && finish
        ;;
    screen)
        output=$(hyprctl -j monitors | jq -r '.[] | select(.focused) | .name')
        grim -o "$output" "$file" && finish
        ;;
    window)
        geometry=$(hyprctl -j activewindow | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')
        grim -g "$geometry" "$file" && finish
        ;;
    *)
        echo "usage: $0 [region-edit|region|screen|window]" >&2
        exit 2
        ;;
esac
