CLOUD_HISTFILES="$HOME/Library/Mobile Documents/com~apple~CloudDocs/Terminal/history"
LOCAL_HISTFILE="$HOME/.zsh_history"
HOSTNAME=$(hostname -s | tr '[:upper:]' '[:lower:]')
CLOUD_HISTFILE="$CLOUD_HISTFILES/$HOSTNAME.zsh-history"

histutils --format zsh "$LOCAL_HISTFILE" "$CLOUD_HISTFILES"/*.{zsh-history,fish-history} | sponge "$LOCAL_HISTFILE"
cp "$LOCAL_HISTFILE" "$CLOUD_HISTFILE"
