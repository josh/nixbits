lockfile_check="lockfile-drv-changed"

dry_run=false
case "${1:-}" in
--dry-run | --list) dry_run=true ;;
"") ;;
*)
  echo "usage: gh-close-noop-prs [--dry-run|--list]" >&2
  exit 2
  ;;
esac

stderr_file=$(mktemp)
trap 'rm -f "$stderr_file"' EXIT

urls_output=$(gh search prs --owner josh --state open --label noop --limit 1000 --json url --jq '.[].url')
urls=()
[ -z "$urls_output" ] || mapfile -t urls <<<"$urls_output"

needs_review=0
errors=0

for url in "${urls[@]}"; do
  if checks_json=$(gh pr checks "$url" --json name,bucket 2>"$stderr_file"); then
    :
  elif [ -z "$checks_json" ]; then
    checks_error=$(<"$stderr_file")
    if [[ $checks_error != *"no checks reported"* ]]; then
      errors=$((errors + 1))
      echo "error $url (gh pr checks: $checks_error)" >&2
      continue
    fi
  fi
  checks_json=${checks_json:-[]}

  lockfile_failed=$(jq --arg name "$lockfile_check" \
    'any(.[]; .name == $name and .bucket == "fail")' <<<"$checks_json")

  if [ "$lockfile_failed" != "true" ]; then
    echo "skip $url (${lockfile_check} not failing)"
    continue
  fi

  other_status=$(jq --raw-output --arg name "$lockfile_check" '
    [ .[] | select(.name != $name) | .bucket ] as $b
    | if   any($b[]; . == "fail" or . == "cancel") then "bad"
      elif any($b[]; . == "pending")               then "pending"
      else                                              "ok"
      end
  ' <<<"$checks_json")

  case "$other_status" in
  bad)
    failed_checks=$(jq --raw-output --arg name "$lockfile_check" \
      '[ .[] | select(.name != $name and (.bucket == "fail" or .bucket == "cancel")) | .name ] | join(", ")' \
      <<<"$checks_json")
    needs_review=$((needs_review + 1))
    echo "review $url (other checks failing: $failed_checks)"
    ;;
  pending)
    echo "defer $url (other checks pending)"
    ;;
  ok)
    if [ "$dry_run" = true ]; then
      echo "close $url"
    elif gh pr close "$url" --delete-branch >/dev/null 2>"$stderr_file"; then
      echo "close $url"
    else
      errors=$((errors + 1))
      echo "error $url (gh pr close: $(<"$stderr_file"))" >&2
    fi
    ;;
  esac
done

if [ "$needs_review" -gt 0 ] || [ "$errors" -gt 0 ]; then
  exit 1
fi
