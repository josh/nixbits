CLOUD_HISTFILES="$HOME/Library/Mobile Documents/com~apple~CloudDocs/Terminal/history"
LOCAL_HISTFILE="$HOME/.local/share/fish/fish_history"
HOSTNAME=$(hostname -s | tr '[:upper:]' '[:lower:]')
CLOUD_HISTFILE="$CLOUD_HISTFILES/$HOSTNAME.fish-history"

histutils \
  --output-format fish \
  --tail 50000 \
  --output "$LOCAL_HISTFILE" \
  --output "$CLOUD_HISTFILE" \
  "$LOCAL_HISTFILE" "$CLOUD_HISTFILES"/*.{zsh-history,fish-history}
