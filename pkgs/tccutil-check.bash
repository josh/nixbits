if [ $# -ne 2 ]; then
  echo "usage: tccutil-check <client> <service>"
  exit 1
fi

client="$1"
service="$2"
query="SELECT service FROM access WHERE client = '$client' AND service = '$service'"

db="/Library/Application Support/com.apple.TCC/TCC.db"
if sqlite3 -readonly "$db" -json "$query" | jq --exit-status 'length > 0' >/dev/null; then
  echo "$client has $service access" >&2
  exit 0
fi

db="$HOME/Library/Application Support/com.apple.TCC/TCC.db"
if sqlite3 -readonly "$db" -json "$query" | jq --exit-status 'length > 0' >/dev/null; then
  echo "$client has $service access" >&2
  exit 0
fi

echo "$client missing $service access" >&2
exit 1
