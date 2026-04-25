#!/usr/bin/env bash

PLAYER="spotify"
MAX_LEN=40

emit() {
    local status="$1" artist="$2" title="$3" album="$4"

    if [[ -z "$status" || "$status" == "No players found" ]]; then
        echo '{"text":"","tooltip":"","class":"hidden"}'
        return
    fi

    local icon class
    local class
    case "$status" in
        Playing) class="playing" ;;
        Paused)  class="paused"  ;;
        *)       class="stopped" ;;
    esac

    local track="$artist - $title"
    if (( ${#track} > MAX_LEN )); then
        track="${track:0:MAX_LEN}…"
    fi

    local tooltip
    tooltip=$(printf '%s\n%s\n%s' "$title" "$artist" "$album")

    jq -cn \
        --arg text "$track" \
        --arg tooltip "$tooltip" \
        --arg class "$class" \
        '{text:$text, tooltip:$tooltip, class:$class, alt:$class}'
}

STATUS=$(playerctl -p "$PLAYER" status 2>/dev/null)
if [[ -n "$STATUS" && "$STATUS" != "No players found" ]]; then
    emit "$STATUS" \
        "$(playerctl -p "$PLAYER" metadata artist 2>/dev/null)" \
        "$(playerctl -p "$PLAYER" metadata title  2>/dev/null)" \
        "$(playerctl -p "$PLAYER" metadata album  2>/dev/null)"
else
    emit ""
fi

while true; do
    playerctl -p "$PLAYER" metadata -F \
        --format '{{status}}|{{artist}}|{{title}}|{{album}}' 2>/dev/null \
    | while IFS='|' read -r status artist title album; do
        emit "$status" "$artist" "$title" "$album"
    done
    emit ""
    sleep 2
done
