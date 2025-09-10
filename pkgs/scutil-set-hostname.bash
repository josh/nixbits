# shellcheck source=/dev/null
source "$XTRACE_PATH/share/bash/xtrace.bash"

usage() {
  echo "usage: scutil-sync-hostname [--dry-run] [COMPUTER_NAME]" >&2
}

dry_run=false
flushcache=false
expected_computer_name=""

for arg in "$@"; do
  case "$arg" in
  "--dry-run")
    dry_run=true
    ;;
  *)
    expected_computer_name="$arg"
    ;;
  esac
done

actual_computer_name=$(scutil --get ComputerName)
actual_local_host_name=$(scutil --get LocalHostName)
actual_host_name=$(scutil --get HostName)

if [ -z "$expected_computer_name" ]; then
  expected_computer_name="$actual_computer_name"
  echo "warn: using '$actual_computer_name' as computer name" >&2
fi

expected_local_host_name=$(echo "$expected_computer_name" | tr ' ' '-' | tr -cd '[:alnum:]-')
expected_host_name=$(echo "$expected_local_host_name" | tr '[:upper:]' '[:lower:]').local

if [ "$actual_computer_name" != "$expected_computer_name" ]; then
  x-dry-run $dry_run -- scutil --set ComputerName "$expected_computer_name"
  flushcache=true
fi

if [ "$actual_local_host_name" != "$expected_local_host_name" ]; then
  x-dry-run $dry_run -- scutil --set LocalHostName "$expected_local_host_name"
  flushcache=true
fi

if [ "$actual_host_name" != "$expected_host_name" ]; then
  x-dry-run $dry_run -- scutil --set HostName "$expected_host_name"
  flushcache=true
fi

if [ "$flushcache" == true ]; then
  x-dry-run $dry_run -- dscacheutil -flushcache
fi
