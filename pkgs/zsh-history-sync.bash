CLOUD_HISTFILES="$HOME/Library/Mobile Documents/com~apple~CloudDocs/Terminal/history"
LOCAL_HISTFILE="$HOME/.zsh_history"
HOSTNAME=$(hostname -s | tr '[:upper:]' '[:lower:]')
CLOUD_HISTFILE="$CLOUD_HISTFILES/$HOSTNAME.zsh-history"

histutils \
  --output-format zsh --output "$LOCAL_HISTFILE" \
  "$LOCAL_HISTFILE" "$CLOUD_HISTFILES"/*.{zsh-history,fish-history}
cp "$LOCAL_HISTFILE" "$CLOUD_HISTFILE"
