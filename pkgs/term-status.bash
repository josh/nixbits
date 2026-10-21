usage() {
  echo "usage: term-status [--app APP] [--id ID] [--progress N] STATE [MESSAGE]" >&2
  echo "       term-status [--app APP] [--id ID] [--msg MESSAGE] -- COMMAND [ARGS...]" >&2
}

app=""
id=""
progress=""
msg=""
run=false

while [ $# -gt 0 ]; do
  case "$1" in
  --app | --id | --progress | --msg)
    if [ $# -lt 2 ]; then
      usage
      exit 1
    fi
    declare "${1#--}=$2"
    shift 2
    ;;
  --)
    run=true
    shift
    break
    ;;
  -*)
    usage
    exit 1
    ;;
  *)
    break
    ;;
  esac
done

tty="${TERM_STATUS_TTY:-/dev/tty}"
enabled=false
if { [ "${TERM_PROGRAM:-}" = rex ] || [ -n "${REX_SESSION:-}" ]; } && { true >>"$tty"; } 2>/dev/null; then
  enabled=true
fi

report() {
  local pairs="state=$1"
  [ -n "$id" ] && pairs+=":id=$id"
  [ -n "$app" ] && pairs+=":app=$app"
  [ -n "$progress" ] && pairs+=":progress=$progress"
  if [ -n "${2:-}" ]; then
    pairs+=":msg=$(printf '%s' "$2" | tr -d '\000-\037\177' | base64 | tr -d '\n')"
  fi
  local sequence=$'\e]7501;'"$pairs"$'\e\\'
  if [ -n "${TMUX:-}" ]; then
    sequence=$'\ePtmux;'"${sequence//$'\e'/$'\e\e'}"$'\e\\'
  fi
  if [ "$enabled" = true ]; then
    printf '%s' "$sequence" >>"$tty"
  fi
}

if [ "$run" = false ]; then
  if [ $# -lt 1 ] || [ $# -gt 2 ]; then
    usage
    exit 1
  fi
  report "$1" "${2:-}"
  exit 0
fi

if [ $# -eq 0 ]; then
  usage
  exit 1
fi

if [ -z "$msg" ]; then
  msg="$(basename "$1")"
fi

trap 'report idle; exit 130' INT
report working "$msg"
status=0
"$@" || status=$?
case "$status" in
0)
  report "done" "$msg"
  ;;
130)
  report idle
  ;;
*)
  report error "$msg failed (exit $status)"
  ;;
esac
exit "$status"
