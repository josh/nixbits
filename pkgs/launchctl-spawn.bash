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
# shellcheck disable=SC2329 # invoked via the EXIT trap
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

last_exit_code() {
  launchctl print "gui/$UID/$label" 2>/dev/null |
    grep --max-count=1 "last exit code = " |
    grep --only-matching --extended-regexp "[0-9]+$" || true
}

trap cleanup EXIT
bootout
submit "$@"

# The spawn is asynchronous: launchctl submit returns once the job is
# registered, before it runs. "last exit code" stays "(never exited)" until
# the first run completes, so poll for a numeric code instead of the active
# count, which is still 0 in the pre-spawn window.
exit_code=""
while [ -z "$exit_code" ]; do
  if ! launchctl print "gui/$UID/$label" >/dev/null 2>&1; then
    echo "error: launchd job $label disappeared" >&2
    exit 1
  fi
  exit_code=$(last_exit_code)
  [ -n "$exit_code" ] || sleep 0.1
done

cat "$job_stdout" >&1
cat "$job_stderr" >&2
exit "$exit_code"
