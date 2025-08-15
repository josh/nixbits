CLOUD_HISTFILES="$HOME/Library/Mobile Documents/com~apple~CloudDocs/Terminal/history"
HOSTNAME=$(hostname -s | tr '[:upper:]' '[:lower:]')
cp "$HOME/.local/share/fish/fish_history" "$CLOUD_HISTFILES/${HOSTNAME}.fish-history"

# Delete old file format
if [ -f "$CLOUD_HISTFILES/${HOSTNAME}-fish.zsh-history" ]; then
  rm "$CLOUD_HISTFILES/${HOSTNAME}-fish.zsh-history"
fi

# TOOD: Import other fish history files
# TODO: Import other zsh history files
