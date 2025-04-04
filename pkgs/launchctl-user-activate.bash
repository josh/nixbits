# shellcheck source=/dev/null
source "$XTRACE_PATH/share/bash/xtrace.bash"

if [ $# -eq 0 ]; then
  echo "usage: launchctl-user-activate NEW [OLD]" >&2
  exit 1
fi

if [ -z "$UID" ]; then
  echo "error: UID is not set" >&2
  exit 1
fi

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

wait_for_loaded() {
  local label="$1"
  local timeout="${2:-30}"
  local start_time=$SECONDS

  if is_loaded "$label"; then
    return 0
  fi

  echo "Waiting for $label to load..." >&2

  while ! is_loaded "$label"; do
    if [ $((SECONDS - start_time)) -ge "$timeout" ]; then
      echo "Timed out waiting for $label to load" >&2
      return 1
    fi
    sleep 1
  done

  return 0
}

wait_for_unloaded() {
  local label="$1"
  local timeout="${2:-30}"
  local start_time=$SECONDS

  if ! is_loaded "$label"; then
    return 0
  fi

  echo "Waiting for $label to unload..." >&2

  while is_loaded "$label"; do
    if [ $((SECONDS - start_time)) -ge "$timeout" ]; then
      echo "Timed out waiting for $label to unload" >&2
      return 1
    fi
    sleep 1
  done

  return 0
}

install_agent() {
  local label="$1"
  local src="$2"
  local dst="$HOME/Library/LaunchAgents/$label.plist"
  local result=0

  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    :
  else
    remove_agent "$label" || result=1
  fi

  if [ ! -e "$dst" ]; then
    x ln -s "$src" "$dst" || result=1
  fi

  if ! is_loaded "$label"; then
    x launchctl bootstrap "gui/$UID" "$dst" || result=1
    if ! wait_for_loaded "$label"; then
      result=1
    fi
  fi

  return $result
}

remove_agent() {
  local label="$1"
  local dst="$HOME/Library/LaunchAgents/$label.plist"
  local result=0

  if is_loaded "$label"; then
    x launchctl bootout "gui/$UID/$label" || result=1
    if ! wait_for_unloaded "$label"; then
      result=1
    fi
  fi

  if [ -f "$dst" ]; then
    x rm "$dst" || result=1
  fi

  return $result
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
