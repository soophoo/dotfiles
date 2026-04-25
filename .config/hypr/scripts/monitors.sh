#!/usr/bin/env bash
# Auto-arrange Hyprland monitors. No hardcoding — uses whatever is connected.
# Layout: external monitors left-to-right at preferred mode, laptop panel on the right.

set -euo pipefail

# Read connected monitors as: name<TAB>width<TAB>height<TAB>refresh
mapfile -t MONS < <(
    hyprctl -j monitors all \
    | python3 -c '
import json, sys
mons = json.load(sys.stdin)
for m in mons:
    if m.get("disabled"):
        continue
    name = m["name"]
    # Pick the highest-resolution / highest-refresh available mode.
    best = (0, 0, 0.0)
    for mode in m.get("availableModes", []):
        # mode looks like "2560x1440@59.95100Hz"
        try:
            res, rate = mode.split("@")
            w, h = (int(x) for x in res.split("x"))
            r = float(rate.rstrip("Hz"))
            if (w*h, r) > (best[0]*best[1], best[2]):
                best = (w, h, r)
        except Exception:
            pass
    if best == (0, 0, 0.0):
        best = (m["width"], m["height"], m.get("refreshRate", 60.0))
    print(f"{name}\t{best[0]}\t{best[1]}\t{best[2]:.2f}")
'
)

if [ ${#MONS[@]} -eq 0 ]; then
    echo "[monitors] no monitors detected" >&2
    exit 0
fi

# Split into laptop panel (eDP*) and externals.
laptop=""
externals=()
for line in "${MONS[@]}"; do
    name="${line%%	*}"
    case "$name" in
        eDP*|LVDS*) laptop="$line" ;;
        *)          externals+=("$line") ;;
    esac
done

apply() {
    local line="$1" x="$2" scale="$3"
    IFS=$'\t' read -r name w h r <<< "$line"
    echo "[monitors] $name -> ${w}x${h}@${r} at ${x}x0 scale ${scale}"
    hyprctl keyword monitor "$name,${w}x${h}@${r},${x}x0,${scale}" >/dev/null
}

x=0
# 1. Place externals first, left-to-right.
for line in "${externals[@]}"; do
    IFS=$'\t' read -r _ w _ _ <<< "$line"
    apply "$line" "$x" "1"
    x=$(( x + w ))
done

# 2. Laptop panel: alone if no externals, otherwise to the right of them.
if [ -n "$laptop" ]; then
    if [ ${#externals[@]} -eq 0 ]; then
        apply "$laptop" 0 "1"
    else
        apply "$laptop" "$x" "1"
    fi
fi
