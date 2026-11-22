#!/bin/sh

PALETTE="$HOME/.config/polybar/palette.env"
[ -f "$PALETTE" ] && . "$PALETTE"
ACCENT=${ACCENT:-'#E6E6E6'}
DIM=${DIM:-'#7A7A7A'}

echo "%{F$ACCENT} %{F$DIM}$(ip -o -4 addr show up scope global | awk '{print $4}' | cut -d/ -f1)%{u-}"
