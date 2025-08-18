CLOUD_HISTFILES="$HOME/Library/Mobile Documents/com~apple~CloudDocs/Terminal/history"
LOCAL_HISTFILE="$HOME/.local/share/fish/fish_history"
HOSTNAME=$(hostname -s | tr '[:upper:]' '[:lower:]')
CLOUD_HISTFILE="$CLOUD_HISTFILES/$HOSTNAME.fish-history"

# dry run
histutils --format fish "$LOCAL_HISTFILE" "$CLOUD_HISTFILES"/*.{zsh-history,fish-history} >/dev/null
# histutils --format fish "$LOCAL_HISTFILE" "$CLOUD_HISTFILES"/*.{zsh-history,fish-history} | sponge "$LOCAL_HISTFILE"
# cp "$LOCAL_HISTFILE" "$CLOUD_HISTFILE"
