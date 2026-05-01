#!/bin/bash
shift || true

# A script to display network speed
get_interface() {
    ip route | awk '/default/ { print $5; exit }'
}

pick_fallback_interface() {
    for path in /sys/class/net/*; do
        iface="${path##*/}"
        [ "$iface" = "lo" ] && continue
        [ -r "/sys/class/net/$iface/operstate" ] || continue
        state=$(cat "/sys/class/net/$iface/operstate")
        [ "$state" = "up" ] && echo "$iface" && return
    done
}

format_rate() {
    rate_kb=$1
    if [ "$rate_kb" -ge 1024 ]; then
        printf "%.1fMB/s" "$(awk "BEGIN { print $rate_kb / 1024 }")"
    else
        printf "%dKB/s" "$rate_kb"
    fi
}

interface="$(get_interface)"
if [ -z "$interface" ]; then
    interface="$(pick_fallback_interface)"
fi

if [ -z "$interface" ]; then
    echo " 0KB/s  0KB/s"
    exit 0
fi

cache_dir="${XDG_RUNTIME_DIR:-/tmp}"
cache_file="$cache_dir/waybar-network-speed-$UID-$interface"
now_tx=$(cat "/sys/class/net/$interface/statistics/tx_bytes")
now_rx=$(cat "/sys/class/net/$interface/statistics/rx_bytes")

if [ -f "$cache_file" ]; then
    read -r prev_tx prev_rx < "$cache_file"
else
    prev_tx=$now_tx
    prev_rx=$now_rx
fi

tx_speed=$(( (now_tx - prev_tx) / 1024 ))
rx_speed=$(( (now_rx - prev_rx) / 1024 ))

echo "$now_tx $now_rx" > "$cache_file"

DL_ICON='<span color="#00ff66"></span>'
UL_ICON='<span color="#00ff66"></span>'
echo "$DL_ICON $(format_rate "$rx_speed") $UL_ICON $(format_rate "$tx_speed")"
