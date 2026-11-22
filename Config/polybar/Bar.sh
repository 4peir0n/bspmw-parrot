#!/usr/bin/env sh

killall -q polybar

while pgrep -u "$(id -u)" -x polybar >/dev/null; do sleep 1; done

polybar primary -c ~/.config/polybar/workspace.ini &
polybar htb -c ~/.config/polybar/current.ini &
polybar target -c ~/.config/polybar/current.ini &
