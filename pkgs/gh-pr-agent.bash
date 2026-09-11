# shellcheck source=/dev/null
source "$XTRACE_PATH/share/bash/xtrace.bash"

target="${1:-}"
if [[ $target =~ ^(https?://)?(www\.)?github\.com/([^/]+)/([^/]+)/pull/([0-9]+) ]]; then
  owner="${BASH_REMATCH[3]}"
  repo="${BASH_REMATCH[4]}"
  number="${BASH_REMATCH[5]}"
elif [[ $target =~ ^([^/]+)/([^/#]+)#([0-9]+)$ ]]; then
  owner="${BASH_REMATCH[1]}"
  repo="${BASH_REMATCH[2]}"
  number="${BASH_REMATCH[3]}"
else
  echo "error: could not parse pull request from '$target'" >&2
  exit 1
fi

pr=$(gh pr view "$number" --repo "$owner/$repo" \
  --json 'headRefName,headRepositoryOwner,isCrossRepository,url' \
  --jq '[.url, .headRefName, .headRepositoryOwner.login, (.isCrossRepository | tostring)] | @tsv')
IFS=$'\t' read -r url branch head_owner is_cross <<<"$pr"

root="${PROJECTS_DIR:-$HOME/Developer}"
dir="$root/$repo"

if [ ! -d "$dir" ]; then
  mkdir -p "$root"
  cd "$root" || exit 1
  x jj-clone "$owner/$repo"
else
  if [ ! -d "$dir/.jj" ]; then
    echo "error: $dir is not a jj repo" >&2
    exit 1
  fi
  if [ ! -d "$dir/.git" ]; then
    echo "error: $dir is not colocated with git" >&2
    exit 1
  fi
  remotes=$(cd "$dir" && jj --ignore-working-copy git remote list)
  if ! grep --quiet --extended-regexp "[:/]$owner/$repo(\.git)?\$" <<<"$remotes"; then
    echo "error: $dir does not point at $owner/$repo" >&2
    exit 1
  fi
fi
cd "$dir" || exit 1

if [ "$is_cross" = "true" ] && [ "$head_owner" != "$owner" ]; then
  remote="$head_owner"
  if ! jj --ignore-working-copy git remote list | grep --quiet "^$remote "; then
    x jj git remote add "$remote" "https://github.com/$head_owner/$repo.git"
  fi
  x jj git fetch --remote "$remote"
else
  remote="origin"
  x jj git fetch --all-remotes
fi

if ! jj --ignore-working-copy bookmark list --tracked --template 'name ++ "\n"' |
  grep --quiet --line-regexp --fixed-strings "$branch"; then
  x jj bookmark track "$branch@$remote"
fi
x jj edit "$branch"

skills=(
  # keep-sorted start
  codex-triage
  gh-pr-ci
  # keep-sorted end
)

skill=$(printf '%s\n' "${skills[@]}" | gum choose --header "Skill") || exit $?
agent=$(gum choose --header "Agent" claude codex) || exit $?

case "$agent" in
claude) x-exec claude "/$skill $url" ;;
codex) x-exec codex "\$$skill $url" ;;
esac
