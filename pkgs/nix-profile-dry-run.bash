if [ $# -eq 0 ]; then
  echo "Usage: nix-profile-dry-run <install|remove|upgrade>"
  exit 1
fi

if [[ $1 != "install" && $1 != "remove" && $1 != "upgrade" ]]; then
  echo "Usage: nix-profile-dry-run <install|remove|upgrade>"
  exit 1
fi

command="$1"
shift

if [ "$(id -u)" -eq 0 ]; then
  nix_profile_dir="${NIX_STATE_DIR:-/nix/var/nix}/profiles/per-user/root"
else
  nix_profile_dir="${XDG_STATE_HOME:-$HOME/.local/state}/nix/profiles"
fi
current_profile=$(readlink -f "$nix_profile_dir/profile")

profile_dir=$(mktemp -d)
pushd "$profile_dir" >/dev/null || exit 1
ln -s "$current_profile" profile-1-link
ln -s profile-1-link profile
popd >/dev/null || exit 1

nix profile "$command" --profile "$profile_dir/profile" "$@"
readlink -f "$profile_dir/profile"
