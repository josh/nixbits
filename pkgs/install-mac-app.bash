usage() {
  echo "usage: install-mac-app [--dry-run] [--appdir /Applications] /nix/store/<drv>" >&2
}

dry_run=false
nix_store_path=""
app_dir="/Applications"

while [ $# -gt 0 ]; do
  case "$1" in
  --dry-run)
    dry_run=true
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
    if [ -n "$nix_store_path" ]; then
      echo "error: too many arguments" >&2
      exit 1
    fi
    nix_store_path="$1"
    shift
    ;;
  esac
done

if [ -z "$nix_store_path" ]; then
  echo "error: missing NIX_STORE_PATH argument" >&2
  exit 1
fi

if [ ! -d "$nix_store_path" ]; then
  echo "error: src is not a directory" >&2
  exit 1
fi

if [[ $nix_store_path != /nix/store/* ]]; then
  echo "error: src must be a directory under /nix/store" >&2
  exit 1
fi

apps=("$nix_store_path/Applications/"*.app)

if [ ${#apps[@]} -eq 0 ]; then
  echo "error: no .app found in $nix_store_path/Applications/" >&2
  exit 1
fi

if [ ${#apps[@]} -gt 1 ]; then
  echo "error: multiple .app found in $nix_store_path/Applications/" >&2
  for app in "${apps[@]}"; do
    echo "  - $(basename "$app")" >&2
  done
  exit 1
fi

src="${apps[0]}/"
app_name="$(basename "$src")"
dst="$app_dir/$app_name/"

cdhash() {
  codesign --verbose=3 --display "$1" 2>&1 |
    grep --only-matching 'CDHash=\S*' |
    cut --delimiter='=' --fields=2
}

src_hash="$(cdhash "$src")"
dst_hash=""

if [ -d "$dst" ]; then
  dst_hash="$(cdhash "$dst" || echo "invalid")"
fi

if [ "$src_hash" = "$dst_hash" ]; then
  exit 0
fi

if [ "$dry_run" = true ]; then
  echo "Would install $src to $app_dir/" >&2
  exit 0
fi

x() {
  echo "+" "$@" >&2
  "$@"
}

x rsync \
  --archive \
  --checksum \
  --chmod=-w \
  --copy-unsafe-links \
  --delete \
  --no-group \
  --no-owner \
  --verbose \
  "$src" \
  "$dst"
