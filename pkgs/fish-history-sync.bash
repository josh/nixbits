tmpfile="$(mktemp /tmp/fish_history.XXX)"
cleanup() {
  rm -f "$tmpfile"
}
trap cleanup EXIT
trap cleanup SIGINT

CLOUD_HISTFILES="$HOME/Library/Mobile Documents/com~apple~CloudDocs/Terminal/history"
LOCAL_HISTFILE="$HOME/.local/share/fish/fish_history"
HOSTNAME=$(hostname -s | tr '[:upper:]' '[:lower:]')
CLOUD_HISTFILE="$CLOUD_HISTFILES/$HOSTNAME.fish-history"
# LOCAL_COUNT=$(wc -l <"$LOCAL_HISTFILE")

sponge "$CLOUD_HISTFILE" <"$LOCAL_HISTFILE"

histutils --format fish "$CLOUD_HISTFILES"/*.{zsh-history,fish-history} >"$tmpfile"
# TMP_COUNT=$(wc -l <"$tmpfile")
# DIFF_COUNT=$((TMP_COUNT - LOCAL_COUNT))

# if [ "$DIFF_COUNT" -eq 0 ]; then
#   echo "Nothing new to sync" >&2
#   exit 0
# fi

# echo "Adding $DIFF_COUNT new lines" >&2
# sponge "$CLOUD_HISTFILE" <"$tmpfile"
# sponge "$LOCAL_HISTFILE" <"$tmpfile"
