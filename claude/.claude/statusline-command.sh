#!/usr/bin/env bash
input=$(cat)

# --- Extract fields ---
model=$(echo "$input" | jq -r '.model.display_name // empty')
model_id=$(echo "$input" | jq -r '.model.name // empty')
used_tokens=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
max_tokens=$(echo "$input" | jq -r '.context_window.context_window_size // 0')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
cost_usd=$(echo "$input" | jq -r '.session_cost_usd // empty')
five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
week_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
week_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

# --- ANSI colors ---
RESET='\033[0m'
DIM='\033[2m'
BOLD='\033[1m'
LBLUE='\033[94m'
WHITE='\033[1;97m'
ORANGE='\033[38;5;214m'

# --- Helper: format token count as K ---
fmt_k() {
  awk -v t="$1" 'BEGIN{ if (t>=1000) printf "%.0fK", t/1000; else printf "%d", t }'
}

# --- Helper: format unix epoch as HH:MM (local time) ---
fmt_time() {
  date -d "@$1" +"%H:%M" 2>/dev/null || date -r "$1" +"%H:%M" 2>/dev/null
}

# --- Helper: format unix epoch as "Mon HH:MM" ---
fmt_day_time() {
  date -d "@$1" +"%a %H:%M" 2>/dev/null || date -r "$1" +"%a %H:%M" 2>/dev/null
}

# --- Helper: estimate cost per token from model id ---
price_per_mtok() {
  local mid="$1"
  case "$mid" in
    *opus-4*|*opus-4-5*)   echo "15.0" ;;  # $15/MTok input
    *sonnet-4*|*sonnet-4-5*|*sonnet-4-6*) echo "3.0" ;;  # $3/MTok input
    *haiku-4*|*haiku-4-5*) echo "0.8" ;;  # $0.80/MTok input
    *) echo "3.0" ;;
  esac
}

out=""

# --- 1. Token circle + count/max + pct ---
if [ -n "$used_pct" ] && [ "$max_tokens" -gt 0 ] 2>/dev/null; then
  pct=$(printf '%.0f' "$used_pct")
  if [ "$pct" -ge 75 ]; then
    circle="🔴"
  elif [ "$pct" -ge 60 ]; then
    circle="🟡"
  else
    circle="🟢"
  fi
  used_fmt=$(fmt_k "$used_tokens")
  max_fmt=$(fmt_k "$max_tokens")
  out="${circle} $(printf "${WHITE}%s/%s${RESET}" "$used_fmt" "$max_fmt") $(printf "${LBLUE}%s%%${RESET}" "$pct")"
elif [ "$used_tokens" -gt 0 ] 2>/dev/null; then
  used_fmt=$(fmt_k "$used_tokens")
  out="🟢 $(printf "${WHITE}%s${RESET}" "$used_fmt")"
fi

# --- 2. Cost ---
if [ -n "$cost_usd" ] && [ "$cost_usd" != "0" ]; then
  # Cost provided directly by Claude Code
  cost_fmt=$(awk -v c="$cost_usd" 'BEGIN{ printf "$%.4f", c }')
  out="${out} $(printf "${DIM}| ${ORANGE}%s${RESET}" "$cost_fmt")"
elif [ "$used_tokens" -gt 0 ] 2>/dev/null && [ -n "$model_id" ]; then
  # Estimate from token count + model pricing
  rate=$(price_per_mtok "$model_id")
  cost_fmt=$(awk -v t="$used_tokens" -v r="$rate" 'BEGIN{ printf "$%.4f", (t/1000000)*r }')
  out="${out} $(printf "${DIM}| ~${ORANGE}%s${RESET}" "$cost_fmt")"
fi

# --- 3. Model name ---
if [ -n "$model" ]; then
  out="${out} $(printf "${DIM}| ${LBLUE}%s${RESET}" "$model")"
fi

# --- 4. 5-hour session usage + reset time ---
if [ -n "$five_pct" ]; then
  five_pct_fmt=$(printf '%.0f' "$five_pct")
  if [ -n "$five_reset" ]; then
    reset_time=$(fmt_time "$five_reset")
    out="${out} $(printf "${DIM}| 5h: ${LBLUE}${five_pct_fmt}%%${RESET}${DIM} - ${reset_time}${RESET}")"
  else
    out="${out} $(printf "${DIM}| 5h: ${LBLUE}${five_pct_fmt}%%${RESET}")"
  fi
fi

# --- 5. Weekly usage + reset time ---
if [ -n "$week_pct" ]; then
  week_pct_fmt=$(printf '%.0f' "$week_pct")
  if [ -n "$week_reset" ]; then
    reset_day_time=$(fmt_day_time "$week_reset")
    out="${out} $(printf "${DIM}| 7d: ${LBLUE}${week_pct_fmt}%%${RESET}${DIM} - ${reset_day_time}${RESET}")"
  else
    out="${out} $(printf "${DIM}| 7d: ${LBLUE}${week_pct_fmt}%%${RESET}")"
  fi
fi

printf '%b' "$out"
