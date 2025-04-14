usage() {
  echo "Usage: jj-pull" >&2
}

# shellcheck source=/dev/null
source "$XTRACE_PATH/share/bash/xtrace.bash"

x jj git fetch --all-remotes
x jj rebase --destination 'trunk()'
