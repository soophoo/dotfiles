alias cc="claude --dangerously-skip-permissions"
alias ccr="claude --resume --dangerously-skip-permissions"

NODE_BIN="/opt/node"

export PATH="$NODE_BIN:$HOME/.local/bin:$PATH"

# Android SDK
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator

# pnpm
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# opencode
export PATH=$HOME/.opencode/bin:$PATH
alias op="opencode"

[ -f ~/.config/secrets.env ] && source ~/.config/secrets.env

# fzf: Ctrl+T (file), Alt+C (cd dir), Ctrl+R (history)
eval "$(fzf --bash)"
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS='--height 50% --layout=reverse --border --preview-window=right:60%'
export FZF_CTRL_T_OPTS="--preview 'bat --color=always --line-range=:200 {} 2>/dev/null || cat {}'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --level=2 --color=always --icons {}'"

# zoxide: smart cd. `cd foo` jumps to frecent match; `cdi` opens fzf picker.
eval "$(zoxide init bash --cmd cd)"

# eza aliases (modern ls)
alias ls='eza --icons --group-directories-first'
alias ll='eza -l --icons --group-directories-first --git'
alias la='eza -la --icons --group-directories-first --git'
alias lt='eza --tree --level=2 --icons'

# bat as colored cat
alias cat='bat --paging=never --style=plain'

# rgf: fuzzy ripgrep — type to search file contents, Enter opens in $EDITOR
rgf() {
  local file
  file=$(rg --line-number --no-heading --color=always --smart-case "${1:-}" |
    fzf --ansi --delimiter : --preview 'bat --color=always --highlight-line {2} {1}' \
        --preview-window 'right,60%,+{2}+3/2') &&
  ${EDITOR:-nvim} "${file%%:*}" "+${file#*:}"
}


NODE_BIN="/opt/node"

export PATH="$PATH:$NODE_BIN:$HOME/.local/bin"
