if [ $# -eq 0 ]; then
  echo "usage: launchctl-user-activate NEW [OLD]" >&2
  exit 1
fi

if [ -z "$UID" ]; then
  echo "error: UID is not set" >&2
  exit 1
fi

x() {
  echo + "$@"
  "$@"
}

labels() {
  find "$1" -maxdepth 1 -name "*.plist" -exec basename {} .plist \; | sort
}

is_loaded() {
  local label="$1"
  if launchctl print "gui/$UID/$label" >/dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

install_agent() {
  local label="$1"
  local src="$2"
  local dst="$HOME/Library/LaunchAgents/$label.plist"

  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    :
  else
    remove_agent "$label"
  fi

  if [ ! -e "$dst" ]; then
    x ln -s "$src" "$dst"
  fi

  if ! is_loaded "$label"; then
    x launchctl bootstrap "gui/$UID" "$dst"
  fi
}

remove_agent() {
  local label="$1"
  local dst="$HOME/Library/LaunchAgents/$label.plist"

  if is_loaded "$label"; then
    x launchctl bootout "gui/$UID/$label"
  fi

  if [ -f "$dst" ]; then
    x rm "$dst"
  fi
}

new_path="$1"
old_path="${2:-}"

if [ ! -d "$new_path" ]; then
  echo "error: $new_path missing" >&2
  exit 1
fi

if [ -z "$old_path" ]; then
  old_path="$new_path"
elif [ -n "$old_path" ] && [ ! -d "$old_path" ]; then
  echo "warn: $2 not a directory" >&2
  old_path="$new_path"
fi

remove_labels=$(comm -2 -3 <(labels "$old_path") <(labels "$new_path"))
keep_labels=$(comm -1 <(labels "$old_path") <(labels "$new_path"))

code=0

for label in $remove_labels; do
  if ! remove_agent "$label"; then
    code=1
  fi
done

for label in $keep_labels; do
  plist=$(readlink -f "$new_path/$label.plist")
  if ! install_agent "$label" "$plist"; then
    code=1
  fi
done

exit $code
