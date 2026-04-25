alias cc="claude --dangerously-skip-permissions"
alias ccr="claude --resume --dangerously-skip-permissions"

NODE_BIN="/opt/node"

export PATH="$NODE_BIN:$HOME/.local/bin:$PATH"

# Fix: OpenSSL 3.6.1 ML-KEM post-quantum TLS causes failures on some networks
export NODE_OPTIONS="--require $HOME/.node-tls-fix.js"

# Android SDK
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator

# pnpm
export PNPM_HOME="/home/eliphaz/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# opencode
export PATH=/home/eliphaz/.opencode/bin:$PATH
alias op="opencode"
