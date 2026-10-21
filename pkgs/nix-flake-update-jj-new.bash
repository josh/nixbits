# shellcheck source=/dev/null
source "$XTRACE_PATH/share/bash/xtrace.bash"

if [ $# -ne 1 ]; then
  echo "usage: nix-flake-update-jj-new <input>" >&2
  exit 1
fi

input="$1"
status() { term-status --app nix-flake-update-jj-new "$@"; }
trap 'status error "Updating $input failed"' ERR
status working "Updating $input"
x jj new main --message "Update $input flake input"

x nix flake update "$input"
if [ -z "$(jj diff --name-only flake.lock)" ]; then
  x jj abandon @
  status "done" "$input is already up to date"
  exit 1
fi

status working "Checking $input update"
x nix flake check --all-systems
x jj bookmark create "update-$input" --revision @
status "done" "Updated $input"
