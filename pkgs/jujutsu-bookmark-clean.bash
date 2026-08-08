# shellcheck source=/dev/null
source "$XTRACE_PATH/share/bash/xtrace.bash"

readarray -t bookmarks < <(jj bookmark list --revisions '::trunk()' --template 'name ++ "\n"' | grep --invert-match --line-regexp --extended-regexp 'main|master')
[ "${#bookmarks[@]}" -eq 0 ] || x jj bookmark delete "${bookmarks[@]}"
