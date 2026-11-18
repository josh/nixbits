zp() {
  if (($# != 1)); then
    print -u2 'Usage: zp <[owner/]repo>'
    return 1
  fi
  local repo="$1" root="${PROJECTS_DIR:-$HOME/Developer}"
  [[ $repo == */* ]] || repo="josh/$repo"
  if [[ ! -d $root ]]; then
    print -ru2 -- "zp: $root does not exist"
    return 1
  fi
  local dir="$root/${repo:t}"
  if [[ -d $dir ]]; then
    z "$dir" || return
    if [[ -d .jj ]]; then
      @jj@ git fetch
    elif [[ -e .git ]]; then
      @git@ fetch
    else
      print -ru2 -- "zp: $dir is not a Git or JJ checkout"
      return 1
    fi
  else
    @clone@ "$repo" "$dir" || return
    z "$dir"
  fi
}
