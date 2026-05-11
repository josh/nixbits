failed=0
mapfile -t repos < <(gh repo list josh --json 'nameWithOwner' --no-archived --limit 1000 --jq '.[] | .nameWithOwner')
for repo in "${repos[@]}"; do
  echo "Processing ${repo}..." >&2
  mapfile -t workflows < <(gh workflow list --repo "$repo" --json 'id' --jq '.[] | .id')
  for workflow in "${workflows[@]}"; do
    mapfile -t runs < <(gh run list --repo "$repo" --workflow "$workflow" --branch main --limit 1 --json 'databaseId,conclusion' --jq 'map(select(.conclusion == "failure"))[] | .databaseId')
    for run in "${runs[@]}"; do
      echo "+ gh run rerun --repo $repo --failed $run" >&2
      if ! gh run rerun --repo "$repo" --failed "$run"; then
        failed=$((failed + 1))
      fi
    done
  done
done
if [ "$failed" -gt 0 ]; then
  echo "$failed rerun(s) failed" >&2
  exit 1
fi
