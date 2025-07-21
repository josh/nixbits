# shellcheck source=/dev/null
source "$XTRACE_PATH/share/bash/xtrace.bash"

readarray -t bookmarks < <(jj bookmark list --revisions '::trunk()' --template 'name ++ "\n"')

for bookmark in "${bookmarks[@]}"; do
  if [[ $bookmark == "main" || $bookmark == "master" ]]; then
    continue
  fi

  x jj bookmark delete "$bookmark"
done
