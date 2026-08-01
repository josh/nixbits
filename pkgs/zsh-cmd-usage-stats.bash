if [ $# -eq 0 ]; then
  echo "usage: zsh-cmd-usage-stats <command>" >&2
  exit 1
fi

command="$1"
history_file="$HOME/.zsh_history"

if [ ! -f "$history_file" ]; then
  echo "$history_file: file not found" >&2
  exit 1
fi

# Escape regex metacharacters so the command matches literally.
escaped=""
for ((i = 0; i < ${#command}; i++)); do
  ch="${command:i:1}"
  case "$ch" in
  [][\\.^\$\(\)\{\}\|\*\+\?]) escaped+="\\$ch" ;;
  *) escaped+="$ch" ;;
  esac
done

# Require a word boundary so "git" does not also count "github".
count=$(grep --count --extended-regexp "^: [0-9]+:[0-9]+;${escaped}( |$)" "$history_file" || true)

if [ "$count" -eq 0 ]; then
  echo "$command used 0 times"
  exit 0
fi

# Multi-line history entries continue on lines without the ": ts:elapsed;"
# prefix; only read the timestamp from a properly prefixed line.
last_timestamp=$(grep --extended-regexp "^: [0-9]+:[0-9]+;${escaped}( |$)" "$history_file" | tail --lines=1 | cut --delimiter=':' --fields=2 | tr --delete ' ' || true)

if [[ $last_timestamp =~ ^[0-9]+$ ]]; then
  last_used=$(date --date="@$last_timestamp" +"%b %-d %Y")
  echo "$command used $count times, last on $last_used"
else
  echo "$command used $count times"
fi
