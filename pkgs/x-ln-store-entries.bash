# shellcheck source=/dev/null
source "$XTRACE_PATH/share/bash/xtrace.bash"

if [ $# -ne 2 ]; then
  echo "usage: x-ln-store-entries <src> <dst>" >&2
  exit 1
fi

src="$1"
dst="$2"
store="${NIX_STORE:-/nix/store}"

if [ ! -d "$src" ]; then
  echo "error: $src not a directory" >&2
  exit 1
fi

if [ -L "$dst" ]; then
  case "$(readlink "$dst")" in
  "$store"/*) x rm "$dst" ;;
  *)
    echo "error: $dst is a symlink outside $store" >&2
    exit 1
    ;;
  esac
fi

if [ -f "$dst" ]; then
  echo "error: $dst is a file" >&2
  exit 1
fi

if [ ! -e "$dst" ]; then
  x mkdir -p "$dst"
fi

shopt -s dotglob nullglob

for file in "$src"/*; do
  [ -e "$file" ] || continue
  name=$(basename "$file")
  abs_src="$(readlink -f "$file")"

  if [ -e "$dst/$name" ] && [ ! -L "$dst/$name" ]; then
    x rm -rf "$dst/$name"
  fi

  if [ ! -L "$dst/$name" ] || [ "$(readlink -f "$dst/$name")" != "$abs_src" ]; then
    x ln -fns "$abs_src" "$dst/$name"
  fi
done

for file in "$dst"/*; do
  [ -L "$file" ] || continue
  name=$(basename "$file")

  case "$(readlink "$file")" in
  "$store"/*)
    if [ ! -e "$src/$name" ]; then
      x rm "$file"
    fi
    ;;
  esac
done
