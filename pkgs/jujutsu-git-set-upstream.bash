# shellcheck source=/dev/null
source "$XTRACE_PATH/share/bash/xtrace.bash"

origin_url=$(jj --ignore-working-copy git remote list | grep '^origin ' | cut -d' ' -f2)

is_fork=$(gh repo view "$origin_url" --json 'isFork' --jq '.isFork')
if [ "$is_fork" = "false" ]; then
  echo "'$origin_url' is not a fork" >&2
  exit 1
fi

orig_upstream_url=$(jj --ignore-working-copy git remote list | grep '^upstream ' | cut -d' ' -f2 || true)
upstream_url=$(gh repo view "$origin_url" --json 'parent' --jq '"https://github.com/\(.parent.owner.login)/\(.parent.name).git"')
upstream_branch=$(gh repo view "$upstream_url" --json 'defaultBranchRef' --jq '.defaultBranchRef.name')

if [ -z "$orig_upstream_url" ]; then
  x jj git remote add upstream "$upstream_url"
elif [ "$orig_upstream_url" != "$upstream_url" ]; then
  x jj git remote set-url upstream "$upstream_url"
fi

x jj git fetch --remote upstream
x jj config set --repo 'revset-aliases."trunk()"' "$upstream_branch@upstream"
