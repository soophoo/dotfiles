#!/usr/bin/env bash

emit() {
    jq -cn \
        --arg text    "$1" \
        --arg tooltip "$2" \
        --arg class   "$3" \
        '{text:$text, tooltip:$tooltip, class:$class, alt:$class}'
}

wifi_level() {
    local sig=$1
    if   (( sig >= 80 )); then echo 4
    elif (( sig >= 60 )); then echo 3
    elif (( sig >= 40 )); then echo 2
    elif (( sig >= 20 )); then echo 1
    else                        echo 0
    fi
}

while true; do
    iface=""
    type=""
    sig=0
    ssid=""

    while IFS=: read -r dev dtype state _conn; do
        [[ "$state" == connected ]] || continue
        case "$dtype" in
            wifi)     iface="$dev"; type="wifi"     ;;
            ethernet) [[ -z "$iface" ]] && { iface="$dev"; type="ethernet"; } ;;
        esac
    done < <(nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device 2>/dev/null)

    if [[ "$type" == "wifi" ]]; then
        while IFS= read -r line; do
            [[ "$line" == yes:* ]] || continue
            rest="${line#yes:}"
            ssid="${rest%:*}"
            sig="${rest##*:}"
            break
        done < <(nmcli -t -f ACTIVE,SSID,SIGNAL device wifi list ifname "$iface" 2>/dev/null)
        [[ "$sig" =~ ^[0-9]+$ ]] || sig=0
        lvl=$(wifi_level "$sig")
        emit "${ssid} ${sig}%" "Wi-Fi: ${ssid} (${sig}%)" "wifi-${lvl}"
    elif [[ "$type" == "ethernet" ]]; then
        ip=$(ip -o -4 addr show "$iface" 2>/dev/null | awk '{print $4}' | head -1)
        emit " " "Ethernet: ${iface} ${ip}" "ethernet"
    else
        emit " " "Disconnected" "wifi-off"
    fi

    sleep 5
done
