#!/usr/bin/env sh
# Rebuild the polybar palette whenever the active feh wallpaper changes.
LAST=""

while :; do
    WP=$(sed -n "s/.*--bg-[a-z]* *'\([^']*\)'.*/\1/p" "$HOME/.fehbg" 2>/dev/null | head -1)
    if [ -n "$WP" ] && [ "$WP" != "$LAST" ]; then
        LAST="$WP"
        "$HOME/.config/polybar/wallpaper-theme.sh" "$WP" >/dev/null 2>&1
    fi
    sleep 5
done
