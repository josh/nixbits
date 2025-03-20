x() {
  echo "+" "$@" >&2
  "$@"
}

src="$1"
dst="$2"

if [ -z "$src" ] || [ -z "$dst" ]; then
  echo "usage: x-ln <src> <dst>" >&2
  exit 1
fi

if [ ! -f "$src" ]; then
  echo "error: $src not found" >&2
  exit 1
fi

if [ -L "$dst" ] && [ "$(readlink -f "$dst")" = "$src" ]; then
  exit 0
fi

parent_dir="$(dirname "$dst")"
if [ ! -d "$parent_dir" ]; then
  x mkdir -p "$parent_dir"
fi

x ln -fs "$src" "$dst"

if [ ! -L "$dst" ] || [ "$(readlink -f "$dst")" != "$src" ]; then
  echo "error: failed to create symlink" >&2
  exit 1
fi
