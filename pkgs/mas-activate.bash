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

mas_output=$(mas list)

declare -A installed_ids_map
while read -r line; do
  id=$(echo "$line" | awk '{print $1}')
  [[ $id =~ ^[0-9]+$ ]] && installed_ids_map["$id"]=1
done <<<"$mas_output"

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

  if [ -z "${installed_ids_map[$app_id]:-}" ]; then
    if [ $dry_run -eq 1 ]; then
      echo "dry-run: + mas install $app_id # $name" >&2
    else
      echo "+ mas install $app_id # $name" >&2
      mas install "$app_id"
    fi
  fi
done
