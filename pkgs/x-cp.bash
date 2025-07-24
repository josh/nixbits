# shellcheck source=/dev/null
source "$XTRACE_PATH/share/bash/xtrace.bash"

if [ $# -lt 2 ]; then
  echo "usage: x-cp [--dry-run] <src> <dst>" >&2
  exit 1
fi

dry_run=false

while [ $# -gt 0 ]; do
  case "$1" in
  --dry-run)
    dry_run=true
    shift
    ;;
  *)
    break
    ;;
  esac
done

src="$1"
dst="$2"

if [ ! -f "$src" ]; then
  echo "error: $src not found" >&2
  exit 1
fi

if [ -f "$dst" ] && cmp -s "$src" "$dst"; then
  exit 0
fi

parent_dir="$(dirname "$dst")"
if [ ! -d "$parent_dir" ]; then
  x-dry-run $dry_run -- mkdir -p "$parent_dir"
fi

x-dry-run $dry_run -- cp "$src" "$dst"

if [ -n "$dry_run" ]; then
  exit 0
fi

if [ ! -f "$dst" ] || ! cmp -s "$src" "$dst"; then
  echo "error: failed to copy file" >&2
  exit 1
fi
