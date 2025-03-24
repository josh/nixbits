x() {
  echo "+" "$@" >&2
  "$@"
}

src="$1"
dst="$2"

if [ -z "$src" ] || [ -z "$dst" ]; then
  echo "usage: x-lndir <src> <dst>" >&2
  exit 1
fi

if [ ! -d "$src" ]; then
  echo "error: $src not a directory" >&2
  exit 1
fi

if [ -f "$dst" ]; then
  echo "error: $dst is a file" >&2
  exit 1
fi

if [ ! -e "$dst" ]; then
  x mkdir -p "$dst"
fi

for file in "$src"/*; do
  [ -e "$file" ] || continue
  name=$(basename "$file")

  if [ ! -L "$dst/$name" ] || [ "$(readlink -f "$dst/$name")" != "$file" ]; then
    x ln -fs "$file" "$dst/$name"
  fi
done

for file in "$dst"/*; do
  [ -e "$file" ] || continue
  name=$(basename "$file")

  if [ ! -L "$file" ]; then
    x rm -rf "$file"
  elif [ ! -e "$src/$name" ]; then
    x rm "$file"
  fi
done
