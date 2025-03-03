current_branch=$(git rev-parse --abbrev-ref HEAD)

default_branch=""
if git show-ref --verify --quiet refs/heads/main; then
  default_branch="main"
elif git show-ref --verify --quiet refs/heads/master; then
  default_branch="master"
else
  echo "error: no default branch" >&2
  exit 1
fi

git branch --merged "$default_branch" |
  grep --invert-match --regexp "^[ *]*$default_branch$" --regexp "^[ *]*$current_branch$" |
  while read -r branch; do
    branch=${branch#"${branch%%[! ]*}"}
    branch=${branch#"*"}
    branch=${branch#" "}
    echo "Removing branch: $branch" >&2
    git branch --delete "$branch"
  done
