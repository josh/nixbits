usage() {
  echo "usage: launchctl-spawn [--] COMMAND [ARGS...]" >&2
}

[ "${1:-}" = "--" ] && shift

if [ $# -lt 1 ]; then
  usage
  exit 1
fi

random_id="$(date +%s)-$$-$RANDOM"
label="launchctl-spawn-$random_id"

job_stdout="$(mktemp)"
job_stderr="$(mktemp)"
cleanup() {
  rm -f "$job_stdout" "$job_stderr"
  bootout
}

submit() {
  launchctl submit -l "$label" -o "$job_stdout" -e "$job_stderr" -- "$@"
}

bootout() {
  launchctl bootout "gui/$UID/$label" >/dev/null 2>&1 || true
}

is_active() {
  launchctl print "gui/$UID/$label" 2>/dev/null | grep --quiet "active count = 1"
}

trap cleanup EXIT
bootout
submit "$@"

while is_active; do
  sleep 0.1
done

cat "$job_stdout" >&1
cat "$job_stderr" >&2
