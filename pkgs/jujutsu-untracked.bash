root="${JJ_WORKSPACE_ROOT:-$(jj root)}"
cd "$root" || exit 1

git_dir=$(jj git root)
index=$(mktemp)
trap 'rm -f "$index"' EXIT
export GIT_DIR="$git_dir" GIT_WORK_TREE="$root" GIT_INDEX_FILE="$index"

git read-tree "$(jj log --revisions @ --no-graph --template commit_id)"
git ls-files --others --directory --exclude=".jj/" "$@"
