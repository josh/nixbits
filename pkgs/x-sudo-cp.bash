# shellcheck source=/dev/null
source "$XTRACE_PATH/share/bash/xtrace.bash"

if [ $# -lt 2 ]; then
  echo "usage: x-sudo-cp <src> <dst>" >&2
  exit 1
fi

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
  x sudo "$COREUTILS_PATH"/bin/mkdir -p "$parent_dir"
fi

x sudo "$COREUTILS_PATH"/bin/cp "$src" "$dst"

if [ ! -f "$dst" ] || ! cmp -s "$src" "$dst"; then
  echo "error: failed to copy file" >&2
  exit 1
fi
