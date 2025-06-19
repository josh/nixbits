if [ $# -eq 0 ]; then
  echo "error: No packages specified." >&2
  exit 1
fi

echo "Building profile" >&2
build() {
  GH_TOKEN=$(gh auth token)
  NIX_CONFIG="extra-access-tokens = github.com=$GH_TOKEN" \
    nix-profile-dry-run \
    upgrade --refresh "$@" \
    --log-format internal-json --verbose 1>&1 2> >(nom --json)
}

if [ "$(id -u)" -eq 0 ]; then
  nix_profile_dir="${NIX_STATE_DIR:-/nix/var/nix}/profiles/per-user/root"
else
  nix_profile_dir="${XDG_STATE_HOME:-$HOME/.local/state}/nix/profiles"
fi
old_profile=$(readlink -f "$nix_profile_dir/profile")
new_profile=$(build "$@")

if [ "$old_profile" = "$new_profile" ]; then
  echo "No profile changes" >&2
  nix-profile-run-hooks post-install "$new_profile" "$old_profile"
  exit 0
fi

echo "Comparing changes" >&2
nvd diff "$old_profile" "$new_profile"

nix-profile-activate "$new_profile"
