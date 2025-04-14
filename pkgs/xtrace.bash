quote-arg() {
  local arg="$1"
  if [[ $arg =~ [[:space:]] || $arg =~ '"' || $arg == *"'"* ]]; then
    escaped=${arg//\'/\'"\'"\'}
    printf "'%s'" "$escaped"
  else
    printf "%s" "$arg"
  fi
}

x-fmt() {
  printf "%s" "$PS4"
  quote-arg "$1"
  shift
  for arg in "$@"; do
    printf " "
    quote-arg "$arg"
  done
  printf "\n"
}

# Pretty much xtrace
# Print command to stderr and run it
x() {
  x-fmt "$@" >&2
  "$@"
}

# Conditionally run command depending on dry run flag
x-dry-run() {
  local dry_run=$1
  shift
  [ "$1" = "--" ] && shift
  case "$dry_run" in
  1 | true)
    printf "[DRY RUN] " >&2
    x-fmt "$@" >&2
    ;;
  *)
    x-fmt "$@" >&2
    "$@"
    ;;
  esac
}

# Always print command, but only log stdout/err on failure
x-quiet() {
  x-fmt "$@" >&2
  if out=$("$@" 2>&1); then
    return 0
  else
    code=$?
    echo "$out" >&2
    return $code
  fi
}

# Only print command and stdout/err on failure, else silence
x-silent() {
  if out=$("$@" 2>&1); then
    return 0
  else
    code=$?
    x-fmt "$@" >&2
    echo "$out" >&2
    return $code
  fi
}

# Print command to stderr and exec it, replacing current process
x-exec() {
  x-fmt "$@" >&2
  exec "$@"
}
