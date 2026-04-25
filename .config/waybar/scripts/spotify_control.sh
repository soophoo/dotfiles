#!/usr/bin/env bash

case "$1" in
    "play-pause")
        playerctl -p spotify play-pause
        ;;
    "next")
        playerctl -p spotify next
        ;;
    "previous")
        playerctl -p spotify previous
        ;;
    "volume-up")
        playerctl -p spotify volume 0.05+
        ;;
    "volume-down")
        playerctl -p spotify volume 0.05-
        ;;
    *)
        echo "Usage: $0 {play-pause|next|previous|volume-up|volume-down}"
        exit 1
        ;;
esac
