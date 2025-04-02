usage() {
  echo "usage: install-mac-app [--dry-run] [--skip-update] [--appdir /Applications] /nix/store/<drv>" >&2
}

dry_run=false
skip_update=false
src=""
app_dir="/Applications"

while [ $# -gt 0 ]; do
  case "$1" in
  --dry-run)
    dry_run=true
    shift
    ;;
  --skip-update)
    skip_update=true
    shift
    ;;
  --appdir)
    if [ $# -lt 2 ]; then
      echo "error: --appdir missing path" >&2
      exit 1
    fi
    app_dir="$2"
    shift 2
    ;;
  -h | --help)
    usage
    exit 0
    ;;
  -*)
    echo "error: unknown option: $1" >&2
    exit 1
    ;;
  *)
    if [ -n "$src" ]; then
      echo "error: too many arguments" >&2
      exit 1
    fi
    src="$1"
    shift
    ;;
  esac
done

if [ ! -d "$app_dir" ]; then
  echo "error: $app_dir not a directory" >&2
  exit 1
fi

if [ -z "$src" ]; then
  echo "error: missing source App" >&2
  exit 1
fi

if [ ! -d "$src" ]; then
  echo "error: src is not a directory" >&2
  exit 1
fi

if [[ $src != /nix/store/* ]]; then
  echo "error: src must be a directory under /nix/store" >&2
  exit 1
fi

if [[ $src != *.app ]]; then
  apps=("$src/Applications/"*.app)

  if [ ${#apps[@]} -eq 0 ]; then
    echo "error: no .app found in $src/Applications/" >&2
    exit 1
  elif [ ${#apps[@]} -gt 1 ]; then
    echo "error: multiple .app found in $src/Applications/" >&2
    exit 1
  fi

  src="${apps[0]}"
fi

app_name="$(basename "$src")"
src="${src%/}"
dst="${app_dir%/}"

if [ "$skip_update" = true ] && [ -d "$dst/$app_name" ]; then
  exit 0
fi

_has_changes() {
  grep --quiet 'Number of regular files transferred: [1-9]'
}

_rsync() {
  if [ "$dry_run" = true ]; then
    if rsync --dry-run --stats "$@" | _has_changes; then
      echo "dry-run: + rsync" "$@" >&2
    fi
  else
    if rsync --stats "$@" | _has_changes; then
      echo "+ rsync" "$@" >&2
    fi
  fi
}

_rsync \
  --archive \
  --checksum \
  --chmod=-w \
  --copy-unsafe-links \
  --delete \
  --no-group \
  --no-owner \
  "$src/" \
  "$dst/$app_name"
