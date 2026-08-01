default_branch=""
if git show-ref --verify --quiet refs/heads/main; then
  default_branch="main"
elif git show-ref --verify --quiet refs/heads/master; then
  default_branch="master"
else
  echo "error: no default branch" >&2
  exit 1
fi

git branch --merged "$default_branch" --format=$'%(refname:short)\t%(worktreepath)' |
  while IFS=$'\t' read -r branch worktree; do
    case "$branch" in
    "$default_branch" | "("*)
      continue
      ;;
    esac

    if [ -n "$worktree" ]; then
      continue
    fi

    echo "Removing branch: $branch" >&2
    git branch --delete "$branch"
  done
