tmpfile="$(mktemp /tmp/zsh_history.XXX)"
cleanup() {
  rm -f "$tmpfile"
}
trap cleanup EXIT
trap cleanup SIGINT

CLOUD_HISTFILES="$HOME/Library/Mobile Documents/com~apple~CloudDocs/Terminal/history"
LOCAL_HISTFILE="$HOME/.zsh_history"
HOSTNAME=$(hostname -s | tr '[:upper:]' '[:lower:]')
CLOUD_HISTFILE="$CLOUD_HISTFILES/$HOSTNAME.history"
LOCAL_COUNT=$(wc -l <"$LOCAL_HISTFILE")

cp "$LOCAL_HISTFILE" "$CLOUD_HISTFILE"

zsh-history-merge "$CLOUD_HISTFILES"/*.history >"$tmpfile"
TMP_COUNT=$(wc -l <"$tmpfile")
DIFF_COUNT=$((TMP_COUNT - LOCAL_COUNT))

if [ "$DIFF_COUNT" -eq 0 ]; then
  echo "Nothing new to sync" >&2
  exit 0
fi

echo "Adding $DIFF_COUNT new lines" >&2
cp "$tmpfile" "$CLOUD_HISTFILE"
cp "$tmpfile" "$LOCAL_HISTFILE"
