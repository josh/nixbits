if [ $# -eq 0 ]; then
  echo "Usage: nix-profile-activate /nix/store/...-profile" >&2
  exit 1
fi

new_profile="$1"
nix_profile_dir="$HOME/.local/state/nix/profiles"
old_profile=$(readlink -f "$nix_profile_dir/profile")

if [ ! -f "$new_profile/manifest.json" ]; then
  echo "Invalid nix profile: $new_profile" >&2
  exit 1
fi

profile_n() {
  local m=0
  for file in "$nix_profile_dir"/profile-*-link; do
    if [[ $file =~ profile-([0-9]+)-link$ ]]; then
      n="${BASH_REMATCH[1]}"
      if ((n > m)); then
        m=$n
      fi
    fi
  done
  echo $((m + 1))
}

if [ "$old_profile" == "$new_profile" ]; then
  echo "Profile already activated" >&2
  exit 0
fi

nix-profile-run-hooks pre-install "$new_profile" "$old_profile"

echo "Installing profile" >&2
profile_link="profile-$(profile_n)-link"
ln -s "$new_profile" "$nix_profile_dir/$profile_link"
ln -sfn "$profile_link" "$nix_profile_dir/profile"

nix-profile-run-hooks post-install "$new_profile" "$old_profile"
