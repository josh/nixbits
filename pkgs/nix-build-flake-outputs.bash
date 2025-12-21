# shellcheck source=/dev/null
source "$XTRACE_PATH/share/bash/xtrace.bash"

flake_uri="$1"

if [ -z "$flake_uri" ]; then
  echo "usage: $0 <flake-uri> [system]" >&2
  exit 1
fi
shift

current_system=$(nix eval --impure --raw --expr 'builtins.currentSystem')

if [ "$#" -gt 0 ]; then
  system="$1"
  shift
else
  system="$current_system"
fi

build_args=()
if [ "$system" != "$current_system" ]; then
  build_args+=("--system" "$system" "--max-jobs" "0")
fi
if [ "$#" -gt 0 ]; then
  build_args+=("$@")
fi

x nix build "${build_args[@]}" --impure --expr "
let
  flake = builtins.getFlake \"$flake_uri\";
  pkgs = flake.inputs.nixpkgs.legacyPackages.${system};
  packages = builtins.attrValues flake.checks.${system};
  checks = builtins.attrValues flake.checks.${system};
in
pkgs.linkFarmFromDrvs \"flake\" (packages ++ checks)"
