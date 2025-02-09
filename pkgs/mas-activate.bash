dir=""
dry_run=0

while [[ $# -gt 0 ]]; do
  case $1 in
  --dry-run)
    dry_run=1
    shift
    ;;
  *)
    dir=$1
    shift
    ;;
  esac
done

if [ ! -d "$dir" ]; then
  echo "Usage: mas-activate /path/to/share/mas [--dry-run]" >&2
  exit 1
fi

mapfile -t installed_ids < <(mas list | awk '{print $1}')

is_installed() {
  local app_id=$1
  for id in "${installed_ids[@]}"; do
    if [[ $id == "$app_id" ]]; then
      return 0
    fi
  done
  return 1
}

for entry in "$dir"/*; do
  [ -e "$entry" ] || continue

  if [ -d "$entry" ]; then
    echo "warning: '$entry' is a directory, skipping" >&2
    continue
  fi

  if [ ! -f "$entry" ] && [ ! -L "$entry" ]; then
    echo "warning: '$entry' is not a regular file or symlink, skipping" >&2
    continue
  fi

  basename=$(basename "$entry")
  if [[ ! $basename =~ ^[0-9]+$ ]]; then
    echo "warning: '$entry' does not have a numeric name, skipping" >&2
    continue
  fi

  name=$(cat "$entry")
  app_id=$basename

  if ! is_installed "$app_id"; then
    if [ $dry_run -eq 1 ]; then
      echo "dry-run: + mas install $app_id # $name" >&2
    else
      echo "+ mas install $app_id # $name" >&2
      mas install "$app_id"
    fi
  else
    echo "$name is installed" >&2
  fi
done
