# shellcheck source=/dev/null
source "$XTRACE_PATH/share/bash/xtrace.bash"

if [ $# -ne 1 ]; then
  echo "usage: nix-flake-update-jj-new <input>" >&2
  exit 1
fi

input="$1"
x jj new main --message "Update $input flake input"

x nix flake update "$input"
if [ -z "$(jj diff --name-only flake.lock)" ]; then
  x jj abandon @
  exit 1
fi

x nix flake check --all-systems
x jj bookmark create "update-$input" --revision @
