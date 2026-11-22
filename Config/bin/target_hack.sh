#!/bin/bash

PALETTE="$HOME/.config/polybar/palette.env"
[ -f "$PALETTE" ] && . "$PALETTE"
ACCENT=${ACCENT:-'#C084FC'}
DIM=${DIM:-'#7A7A7A'}
URGENT=${URGENT:-'#FF6B5C'}

ip_address=$(/bin/cat $HOME/.config/bin/target | awk '{print $1}')
machine_name=$(/bin/cat $HOME/.config/bin/target | awk '{print $2}')

if [ $ip_address ] && [ $machine_name ]; then
    echo "%{T4}%{F$ACCENT}ﱿ%{T-}  %{F$ACCENT}$ip_address%{u-} - $machine_name"
else
    echo "%{T4}%{F$URGENT}ﱿ%{T-} %{u-}%{F$DIM} No target"
fi
