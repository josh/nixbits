# shellcheck source=/dev/null
source "$XTRACE_PATH/share/bash/xtrace.bash"

usage() {
  echo "usage: tmutil-exclude-volume [--dry-run] <volume-path>" >&2
}

dry_run=false
volume_path=""

for arg in "$@"; do
  if [[ $arg == "--dry-run" ]]; then
    dry_run=true
  else
    volume_path="$arg"
  fi
done

if [[ -z $volume_path ]]; then
  usage
  exit 1
fi

if [[ ! -d $volume_path ]] || [[ $volume_path != /Volumes/* ]]; then
  echo "error: '$volume_path' must be a volume" >&2
  exit 1
fi

tmutil_path=$(which tmutil)

if [[ $($tmutil_path isexcluded "$volume_path") == *"[Excluded]"* ]]; then
  exit 0
fi

x-dry-run $dry_run -- sudo "$tmutil_path" addexclusion -v "$volume_path"
