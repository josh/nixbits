# shellcheck source=/dev/null
source "$XTRACE_PATH/share/bash/xtrace.bash"

x jj git init

trunk=$(jj config get 'revset-aliases."trunk()"')
if [[ $trunk =~ ^[^@[:space:]]+@[^@[:space:]]+$ ]]; then
  x jj bookmark track "$trunk"
fi
