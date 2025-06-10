# shellcheck source=/dev/null
source "$XTRACE_PATH/share/bash/xtrace.bash"

usage() {
  echo "usage: scutil-sync-hostname [--dry-run]" >&2
}

dry_run=false

for arg in "$@"; do
  case "$arg" in
  "--dry-run")
    dry_run=true
    ;;
  *)
    usage
    exit 1
    ;;
  esac
done

local_hostname=$(scutil --get LocalHostName)
hostname=$(scutil --get HostName 2>/dev/null || true)

if [ "$hostname" == "${local_hostname}.local" ]; then
  exit 0
fi

x-dry-run $dry_run -- scutil --set HostName "${local_hostname}.local"
