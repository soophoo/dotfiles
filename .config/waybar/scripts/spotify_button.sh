#!/usr/bin/env bash

BUTTON="${1:-prev}"
PLAYER="spotify"

emit_visible() { echo '{"text":" ","class":"'"$BUTTON"'"}'; }
emit_hidden()  { echo '{"text":"","class":"hidden"}'; }

emit_for_status() {
    local s="$1"
    if [[ -n "$s" && "$s" != "No players found" ]]; then
        emit_visible
    else
        emit_hidden
    fi
}

STATUS=$(playerctl -p "$PLAYER" status 2>/dev/null)
emit_for_status "$STATUS"

while true; do
    playerctl -p "$PLAYER" status -F 2>/dev/null | while read -r s; do
        emit_for_status "$s"
    done
    emit_hidden
    sleep 2
done
