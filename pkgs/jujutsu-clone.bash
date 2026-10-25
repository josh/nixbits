usage() {
  echo "Usage: jj-clone <repository> [directory] [-- <jjflags>]" >&2
}

# shellcheck source=/dev/null
source "$XTRACE_PATH/share/bash/xtrace.bash"

parse_repo_source() {
  local repo="$1"

  if [[ $repo =~ ^[a-z+]+:// || $repo =~ ^[^/]+: ]]; then
    echo "$repo"
    return
  fi

  if [[ $repo =~ ^[a-zA-Z0-9_-]+/[a-zA-Z0-9_-]+$ ]]; then
    echo "https://github.com/$repo.git"
    return
  fi

  if [[ $repo =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo "Error: Please specify the full repository path (owner/repo)" >&2
    exit 1
  fi

  echo "Error: Invalid repository format" >&2
  exit 1
}

gitea_source() {
  local repo="$1" json

  [[ -n ${TEA:-} ]] || return 1
  json=$(timeout 5 "$TEA" api "repos/$repo" 2>/dev/null) || return 1
  jq --exit-status --raw-output 'select(.mirror == false) | .clone_url // empty' <<<"$json"
}

if [[ $# -eq 0 ]]; then
  usage
  exit 1
fi

repo="$1"
shift

target=""
if [[ $# -gt 0 && $1 != "--" ]]; then
  target="$1"
  shift
fi

extra_args=()
if [[ $# -gt 0 && $1 == "--" ]]; then
  shift
  extra_args=("$@")
elif [[ $# -gt 0 ]]; then
  usage
  exit 1
fi

source=$(parse_repo_source "$repo")
target="${target:-$(basename "$repo" .git)}"
is_fork=false

if [[ $source == "https://github.com/$repo.git" ]] && gitea=$(gitea_source "$repo"); then
  source="$gitea"
else
  github=$(gh repo view "$repo" --json 'isFork,repositoryTopics' 2>/dev/null || echo '{}')
  is_fork=$(jq --raw-output '.isFork // false' <<<"$github")
  if jq --exit-status '.repositoryTopics // [] | any(.name == "mirror")' <<<"$github" >/dev/null; then
    echo "Warning: $repo is a mirror on GitHub, primary copy not found" >&2
  fi
fi

x jj git clone --colocate "$source" "$target" "${extra_args[@]}"
if [ "$is_fork" = "true" ]; then
  cd "$target" || exit 1
  jj-git-set-upstream
fi
