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

mapfile -t urls < <(gh search prs --owner josh --state open --label noop --limit 1000 --json url --jq '.[].url')

if [ "${#urls[@]}" -eq 0 ]; then
  echo "No open noop PRs found." >&2
  exit 0
fi

closed=()
review=()
deferred=()
skipped=()
errors=0

for url in "${urls[@]}"; do
  checks_json=$(gh pr checks "$url" --json name,bucket 2>/dev/null || true)
  checks_json=${checks_json:-[]}

  lockfile_failed=$(jq --arg name "$lockfile_check" \
    'any(.[]; .name == $name and .bucket == "fail")' <<<"$checks_json")

  if [ "$lockfile_failed" != "true" ]; then
    skipped+=("$url")
    echo "skip   $url (${lockfile_check} not failing)" >&2
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
    review+=("$url (failing: $failed_checks)")
    echo "review $url (other checks failing: $failed_checks)" >&2
    ;;
  pending)
    deferred+=("$url")
    echo "defer  $url (other checks pending)" >&2
    ;;
  ok)
    closed+=("$url")
    if [ "$dry_run" = true ]; then
      echo "+ [dry-run] gh pr close $url --delete-branch" >&2
    else
      echo "+ gh pr close $url --delete-branch" >&2
      if ! gh pr close "$url" --delete-branch; then
        errors=$((errors + 1))
      fi
    fi
    ;;
  esac
done

report() {
  local label=$1
  shift
  echo "${label} $#" >&2
  if [ "$#" -gt 0 ]; then
    printf '  %s\n' "$@" >&2
  fi
}

echo >&2
if [ "$dry_run" = true ]; then
  report "Would close:  " "${closed[@]}"
else
  report "Closed:       " "${closed[@]}"
fi
report "Needs review: " "${review[@]}"
report "Deferred:     " "${deferred[@]}"
report "Skipped:      " "${skipped[@]}"

if [ "${#review[@]}" -gt 0 ] || [ "$errors" -gt 0 ]; then
  exit 1
fi
