# shellcheck source=/dev/null
source "$XTRACE_PATH/share/bash/xtrace.bash"

DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
  --dry-run)
    DRY_RUN=1
    shift
    ;;
  *)
    echo "unknown option: $1" >&2
    exit 1
    ;;
  esac
done

SSH_DIR="$HOME/.ssh"

if [ ! -d "$SSH_DIR" ]; then
  exit 0
fi

fix_permissions() {
  local file="$1"
  local expected_perms="$2"
  local current_perms

  current_perms=$(stat --format '%a' "$file")
  if [ "$current_perms" != "$expected_perms" ]; then
    x-dry-run $DRY_RUN -- chmod "$expected_perms" "$file"
  fi
}

for key in "$SSH_DIR"/id_*; do
  [[ -f $key && $key != *.pub ]] || continue
  fix_permissions "$key" "600"
done

for pubkey in "$SSH_DIR"/id_*.pub; do
  [[ -f $pubkey ]] || continue
  fix_permissions "$pubkey" "644"
done
