# shellcheck source=/dev/null
source "$XTRACE_PATH/share/bash/xtrace.bash"

bookmarks_output=$(jj bookmark list --revisions '::trunk()' --template 'name ++ "\n"')
bookmarks=()
[ -z "$bookmarks_output" ] || readarray -t bookmarks <<<"$bookmarks_output"

for bookmark in "${bookmarks[@]}"; do
  if [[ $bookmark == "main" || $bookmark == "master" ]]; then
    continue
  fi

  x jj bookmark delete "$bookmark"
done
