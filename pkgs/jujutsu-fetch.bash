usage() {
  echo "Usage: jj-fetch" >&2
}

# shellcheck source=/dev/null
source "$XTRACE_PATH/share/bash/xtrace.bash"

x jj git fetch --all-remotes
