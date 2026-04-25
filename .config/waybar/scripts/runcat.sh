#!/usr/bin/env bash

FRAME_COUNT=5
MIN_INTERVAL=0.06
MAX_INTERVAL=1.20
REFRESH_SECS=1

prev_total=0
prev_idle=0
cpu=5
theme="dark"

update_cpu() {
    local _ user nice system idle iowait irq softirq steal total dt di
    read -r _ user nice system idle iowait irq softirq steal _ < /proc/stat
    total=$((user + nice + system + idle + iowait + irq + softirq + steal))

    if (( prev_total > 0 )); then
        dt=$((total - prev_total))
        di=$((idle - prev_idle))
        if (( dt > 0 )); then
            cpu=$(( (dt - di) * 100 / dt ))
            (( cpu < 0 ))   && cpu=0
            (( cpu > 100 )) && cpu=100
        fi
    fi
    prev_total=$total
    prev_idle=$idle
}

detect_theme() {
    local scheme
    scheme=$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null | tr -d "'")
    case "$scheme" in
        prefer-light) theme="light" ; return ;;
        prefer-dark)  theme="dark"  ; return ;;
    esac
    if grep -q 'gtk-application-prefer-dark-theme[[:space:]]*=[[:space:]]*1' \
         "$HOME/.config/gtk-3.0/settings.ini" 2>/dev/null; then
        theme="dark"; return
    fi
    if [[ "$GTK_THEME" == *-[Dd]ark* || "$GTK_THEME" == *:dark ]]; then
        theme="dark"; return
    fi
    theme="dark"
}

interval_for() {
    awk -v p="$1" -v mn="$MIN_INTERVAL" -v mx="$MAX_INTERVAL" \
        'BEGIN { printf "%.3f", mx - (mx - mn) * (p / 100) }'
}

update_cpu
detect_theme
last_check=$(date +%s)
frame=0

while true; do
    now=$(date +%s)
    if (( now - last_check >= REFRESH_SECS )); then
        update_cpu
        detect_theme
        last_check=$now
    fi

    interval=$(interval_for "$cpu")

    jq -cn \
        --arg text " " \
        --arg tooltip "CPU: ${cpu}%  (${theme} mode)" \
        --arg f  "frame-${frame}" \
        --arg th "theme-${theme}" \
        '{text:$text, tooltip:$tooltip, class:[$f, $th], alt:$f}'

    frame=$(( (frame + 1) % FRAME_COUNT ))
    sleep "$interval"
done
