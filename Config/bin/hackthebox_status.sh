#!/bin/sh

PALETTE="$HOME/.config/polybar/palette.env"
[ -f "$PALETTE" ] && . "$PALETTE"
ACCENT=${ACCENT:-'#C084FC'}
DIM=${DIM:-'#7A7A7A'}

IFACE=$(/usr/sbin/ifconfig 2>/dev/null | grep tun0 | awk '{print $1}' | tr -d ':')

if [ "$IFACE" = "tun0" ]; then
    echo "%{T4}%{F$ACCENT}%{T-} %{F$ACCENT}$(/usr/sbin/ifconfig tun0 | grep "inet " | awk '{print $2}')%{u-}"
else
    echo "%{T4}%{F$DIM}%{T-}%{u-} Disconnected"
fi
