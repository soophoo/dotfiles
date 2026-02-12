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

cache_file="/tmp/waybar-network-speed-$interface"
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

# Get WiFi SSID or Ethernet IP for display
extra_info=""

if [ -d "/sys/class/net/$interface/wireless" ]; then
    # WiFi: show network name
    ssid=$(iwgetid "$interface" -r)
    if [ -n "$ssid" ]; then
        extra_info="󰤨 $ssid"
    else
        extra_info="󰤨 unknown"
    fi
else
    # Ethernet: show IP
    ip_addr=$(ip -4 addr show "$interface" | awk '/inet / {print $2}' | cut -d/ -f1)
    if [ -n "$ip_addr" ]; then
        extra_info=" $ip_addr"
    else
        extra_info=" no-ip"
    fi
fi

# Output all together

# Example: " 204KB/s  5KB/s - 󰤨 HomeWifi"
echo " $(format_rate "$rx_speed")  $(format_rate "$tx_speed") - $extra_info"
