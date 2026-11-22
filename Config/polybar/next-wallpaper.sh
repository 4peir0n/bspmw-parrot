#!/usr/bin/env sh
# Pick a random wallpaper, apply it with feh and refresh the bar palette.
DIR="$HOME/Desktop/Wallpapers"
WP=$(find "$DIR" -maxdepth 1 -type f \
    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) \
    | shuf -n 1)
[ -z "$WP" ] && exit 0

/usr/bin/feh --bg-fill "$WP"
"$HOME/.config/polybar/wallpaper-theme.sh" "$WP" >/dev/null 2>&1
