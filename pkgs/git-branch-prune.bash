current_branch=$(git rev-parse --abbrev-ref HEAD)
git branch --merged main |
  grep --invert-match --regexp '^[ *]*main$' --regexp "^[ *]*$current_branch$" |
  while read -r branch; do
    branch=${branch#"${branch%%[! ]*}"}
    branch=${branch#"*"}
    branch=${branch#" "}
    echo "Removing branch: $branch" >&2
    git branch --delete "$branch"
  done
