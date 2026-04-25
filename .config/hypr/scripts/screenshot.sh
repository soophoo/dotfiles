#!/bin/bash

# Screenshot script for Hyprland
# Usage: screenshot.sh [full|region|window]

SCREENSHOT_DIR="$HOME/Pictures/Screenshots"
TIMESTAMP=$(date +"%Y-%m-%d at %H.%M.%S")
FILENAME="Screenshot-$TIMESTAMP.png"
FILEPATH="$SCREENSHOT_DIR/$FILENAME"

# Create screenshots directory if it doesn't exist
mkdir -p "$SCREENSHOT_DIR"

# Function to take screenshot
take_screenshot() {
    local mode="$1"
    
    case "$mode" in
        full)
            # All monitors
            grim "$FILEPATH"
            ;;
        monitor)
            # Current (focused) monitor only
            local output=$(hyprctl activeworkspace -j | jq -r '.monitor')
            grim -o "$output" "$FILEPATH"
            ;;
        region)
            # Region screenshot with slurp
            grim -g "$(slurp)" "$FILEPATH"
            ;;
        window)
            # Active window screenshot
            local geometry=$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')
            grim -g "$geometry" "$FILEPATH"
            ;;
        *)
            echo "Usage: $0 [full|monitor|region|window]"
            exit 1
            ;;
    esac
    
    # Check if screenshot was successful
    if [[ -f "$FILEPATH" ]]; then
        # Copy to clipboard
        wl-copy < "$FILEPATH"
        
        # Send notification with 5000ms timeout (5 seconds)
        notify-send -t 5000 "Screenshot Saved" "Saved to: $FILENAME"
    else
        notify-send -t 5000 "Screenshot Failed" "Failed to take screenshot"
        exit 1
    fi
}

# Take screenshot based on mode
take_screenshot "$1"
