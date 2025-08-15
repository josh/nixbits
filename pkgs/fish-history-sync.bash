CLOUD_HISTFILES="$HOME/Library/Mobile Documents/com~apple~CloudDocs/Terminal/history"
HOSTNAME=$(hostname -s | tr '[:upper:]' '[:lower:]')

cp "$HOME/.local/share/fish/fish_history" "$CLOUD_HISTFILES/${HOSTNAME}.fish-history"
# TODO: Deprecate this export
fish-history-export | sponge "$CLOUD_HISTFILES/${HOSTNAME}-fish.zsh-history"
