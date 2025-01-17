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

run_hooks() {
  echo "Running $1" >&2
  local code=0
  if [ -x "$new_profile/share/nix/hooks/${1}" ]; then
    echo "+ $1" >&2
    if ! "$new_profile/share/nix/hooks/${1}"; then
      code=1
    fi
  fi
  if [ -d "$new_profile/share/nix/hooks/${1}.d" ]; then
    for script in "$new_profile/share/nix/hooks/${1}.d"/*; do
      echo "+ $(basename "$script")" >&2
      if ! "$script"; then
        code=1
      fi
    done
  fi
  if [ $code -ne 0 ]; then
    echo "$1 hooks failed" >&2
    exit $code
  fi
}

run_old_hooks() {
  local code=0
  if [ -d "$new_profile/libexec/$1" ]; then
    for script in "$new_profile/libexec/$1"/*; do
      echo "+ $(basename "$script" ".sh")" >&2
      if ! "$script"; then
        code=1
      fi
    done
  fi
  if [ $code -ne 0 ]; then
    echo "$1 old hooks failed" >&2
    exit $code
  fi
}

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

export NIX_NEW_PROFILE="$new_profile"
export NIX_OLD_PROFILE="$old_profile"

run_hooks pre-install
run_old_hooks pre-install-hooks

echo "Installing profile" >&2
profile_link="profile-$(profile_n)-link"
ln -s "$new_profile" "$nix_profile_dir/$profile_link"
ln -sfn "$profile_link" "$nix_profile_dir/profile"

run_hooks post-install
run_old_hooks post-install-hooks
