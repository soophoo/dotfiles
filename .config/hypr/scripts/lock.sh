#!/usr/bin/env bash

WAYPAPER_CFG="$HOME/.config/waypaper/config.ini"
LOCK_CFG="$HOME/.config/hypr/hyprlock.conf"

if [[ -f "$WAYPAPER_CFG" ]]; then
    wp=$(awk -F'= *' '/^wallpaper/ { print $2 }' "$WAYPAPER_CFG")
    wp="${wp/#\~/$HOME}"
    if [[ -n "$wp" && -f "$wp" ]]; then
        sed -i -E "s|^(\s*path\s*=\s*).*|\1$wp|" "$LOCK_CFG"
    fi
fi

exec hyprlock
