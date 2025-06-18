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
is_fork=$(gh repo view "$repo" --json 'isFork' --jq '.isFork')

x jj git clone --colocate "$source" "$target" "${extra_args[@]}"
if [ "$is_fork" = "true" ]; then
  cd "$target" || exit 1
  jj-git-set-upstream
fi
