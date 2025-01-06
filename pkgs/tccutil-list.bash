if [ $# -eq 0 ]; then
  echo "usage: tccutil-list <client>"
  exit 1
fi

client="$1"
query="SELECT service FROM access WHERE client = '$client'"

db="/Library/Application Support/com.apple.TCC/TCC.db"
sqlite3 -readonly "$db" -json "$query" | jq --raw-output 'map(.service) | unique | .[]'

db="$HOME/Library/Application Support/com.apple.TCC/TCC.db"
sqlite3 -readonly "$db" -json "$query" | jq --raw-output 'map(.service) | unique | .[]'
