CLOUD_HISTFILES="$HOME/Library/Mobile Documents/com~apple~CloudDocs/Terminal/history"
HOSTNAME=$(hostname -s | tr '[:upper:]' '[:lower:]')
CLOUD_HISTFILE="$CLOUD_HISTFILES/${HOSTNAME}-fish.history"
fish-history-export | sponge "$CLOUD_HISTFILE"
