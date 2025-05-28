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

count=$(grep --count ";$command" "$history_file")
last_timestamp=$(grep ";$command" "$history_file" | tail --lines=1 | cut --delimiter=':' --fields=2)
last_used=$(date --date="@$last_timestamp" +"%b %-d %Y")

echo "$command used $count times, last on $last_used"
