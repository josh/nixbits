# shellcheck source=/dev/null
source "$XTRACE_PATH/share/bash/xtrace.bash"

x jj git fetch --all-remotes
x jj new 'trunk()'
