failed=0
repos_output=$(gh repo list josh --json 'nameWithOwner,defaultBranchRef' --no-archived --limit 1000 --jq '.[] | [.nameWithOwner, .defaultBranchRef.name // ""] | @tsv')
repos=()
[ -z "$repos_output" ] || mapfile -t repos <<<"$repos_output"
status() { term-status --app gh-actions-rerun-failed "$@"; }
index=0
for repo_row in "${repos[@]}"; do
  status --progress $((index * 100 / ${#repos[@]})) working "Checking ${repo_row%%$'\t'*}"
  index=$((index + 1))
  IFS=$'\t' read -r repo branch <<<"$repo_row"
  if [ -z "$branch" ]; then
    # Empty repository without a default branch; nothing can have run.
    continue
  fi
  echo "Processing ${repo}..." >&2
  workflows_output=$(gh workflow list --repo "$repo" --json 'id' --jq '.[] | .id')
  workflows=()
  [ -z "$workflows_output" ] || mapfile -t workflows <<<"$workflows_output"
  for workflow in "${workflows[@]}"; do
    runs_output=$(gh run list --repo "$repo" --workflow "$workflow" --branch "$branch" --limit 1 --json 'databaseId,conclusion' --jq 'map(select(.conclusion == "failure"))[] | .databaseId')
    runs=()
    [ -z "$runs_output" ] || mapfile -t runs <<<"$runs_output"
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
  status error "$failed rerun(s) failed"
  exit 1
fi
status "done" "Checked ${#repos[@]} repositories"
