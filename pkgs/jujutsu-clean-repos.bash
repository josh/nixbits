root="${1:-${PROJECTS_DIR:-$HOME/Developer}}"
if [ ! -d "$root" ]; then
  echo "error: no such directory: $root" >&2
  exit 1
fi

junk_dirs='\.[^/]*_cache|\.cache|__pycache__|\.venv|venv|node_modules'
junk_files='result|result-.*|\.DS_Store'
junk="^((.*/)?(($junk_dirs)/|($junk_files)))$"

keep=""
if [ -f "$root/.jjkeep" ]; then
  keep="$(grep --invert-match --extended-regexp '^[[:space:]]*(#|$)' "$root/.jjkeep" || true)"
fi

declare -A state
declare -A detail
names=()
repos=()

for path in "$root"/*; do
  name="$(basename "$path")"
  names+=("$name")
  if grep --quiet --line-regexp --fixed-strings "$name" <<<"$keep"; then
    state["$name"]=keep
    detail["$name"]="listed in .jjkeep"
  elif [ ! -d "$path/.jj" ]; then
    if [ -d "$path/.git" ]; then
      state["$name"]=git-only
      detail["$name"]="not colocated with jj"
    else
      state["$name"]=not-a-repo
    fi
  elif [ -z "$(cd "$path" && jj git remote list)" ]; then
    state["$name"]=no-remote
    detail["$name"]="nothing is backed up"
  else
    repos+=("$name")
  fi
done

if [ "${#repos[@]}" -gt 0 ]; then
  echo "fetching ${#repos[@]} repositories..." >&2
  # shellcheck disable=SC2016
  failed="$(printf '%s\n' "${repos[@]}" |
    xargs -P 8 -I{} bash -c 'cd "$0/$1" || exit 0; jj git fetch --all-remotes >/dev/null 2>&1 || echo "$1"' "$root" {})"
  while IFS= read -r name; do
    [ -n "$name" ] || continue
    state["$name"]=fetch-failed
    detail["$name"]="could not reach remote"
  done <<<"$failed"
fi

for name in "${repos[@]}"; do
  [ -z "${state[$name]:-}" ] || continue
  wip="$(cd "$root/$name" && jj-wip-changes)"
  total="$(grep --count . <<<"$wip" || true)"
  unpushed="$(grep --count '\*$' <<<"$wip" || true)"
  if [ "$total" -eq 0 ]; then
    state["$name"]=clean
  elif [ "$unpushed" -gt 0 ]; then
    state["$name"]=unpushed
    detail["$name"]="$unpushed of $total changes exist only here"
  else
    state["$name"]=active
    detail["$name"]="$total pushed changes in progress"
  fi
done

for name in "${names[@]}"; do
  [[ ${state[$name]} =~ ^(clean|active)$ ]] || continue
  entries="$(cd "$root/$name" && jj-untracked)"
  [ -n "$entries" ] || continue
  junk_entries="$(grep --extended-regexp "$junk" <<<"$entries" || true)"
  removing="$(gum choose --no-limit --selected "$(paste -sd, - <<<"$junk_entries")" \
    --header "$name — untracked files to trash" <<<"$entries")" || exit $?
  while IFS= read -r entry; do
    [ -n "$entry" ] && (cd "$root/$name" && trash "${entry%/}")
  done <<<"$removing"
  kept="$(grep --invert-match --line-regexp --fixed-strings --file=<(echo "$removing") <<<"$entries" |
    grep --invert-match --extended-regexp "$junk" || true)"
  if [ -n "$kept" ]; then
    state["$name"]=review
    detail["$name"]="untracked: $(paste -sd' ' - <<<"$kept")"
  fi
done

candidates=()
preselected=""
for want in fetch-failed no-remote git-only not-a-repo unpushed review active clean keep; do
  for name in "${names[@]}"; do
    [ "${state[$name]}" = "$want" ] || continue
    printf '%-12s %-26s %s\n' "$want" "$name" "${detail[$name]:-}"
    if [ "$want" = clean ]; then
      candidates+=("$name")
      preselected+="${preselected:+,}$name"
    fi
  done
done

[ "${#candidates[@]}" -gt 0 ] || exit 0

trashing="$(printf '%s\n' "${candidates[@]}" |
  gum choose --no-limit --selected "$preselected" --header "Repositories to trash")" || exit $?
[ -n "$trashing" ] || exit 0
gum confirm --default=false "Trash $(grep --count . <<<"$trashing") repositories?" || exit 0
while IFS= read -r name; do
  [ -n "$name" ] && trash "$root/$name"
done <<<"$trashing"
