if [ $# -eq 0 ]; then
  echo "Usage: nix-profile-run-hooks <pre-install|post-install> /nix/store/...-new-profile [/nix/store/...-old-profile]" >&2
  exit 1
fi

hook="$1"
export NIX_NEW_PROFILE="$2"
export NIX_OLD_PROFILE="${3:-}"

if [ "$hook" != "pre-install" ] && [ "$hook" != "post-install" ]; then
  echo "Invalid hook: $hook" >&2
  exit 1
fi

if [ ! -f "$NIX_NEW_PROFILE/manifest.json" ]; then
  echo "Invalid nix profile: $NIX_NEW_PROFILE" >&2
  exit 1
fi
NIX_NEW_PROFILE=$(readlink -f "$NIX_NEW_PROFILE")

if [ -n "$NIX_OLD_PROFILE" ]; then
  if [ ! -f "$NIX_OLD_PROFILE/manifest.json" ]; then
    echo "Invalid nix profile: $NIX_OLD_PROFILE" >&2
    exit 1
  fi
  NIX_OLD_PROFILE=$(readlink -f "$NIX_OLD_PROFILE")
fi

code=0

echo "Running $hook" >&2
if [ -x "$NIX_NEW_PROFILE/share/nix/hooks/$hook" ]; then
  echo "+ $hook" >&2
  if ! "$NIX_NEW_PROFILE/share/nix/hooks/$hook"; then
    code=1
  fi
fi

if [ -d "$NIX_NEW_PROFILE/share/nix/hooks/$hook.d" ]; then
  for script in "$NIX_NEW_PROFILE/share/nix/hooks/$hook.d"/*; do
    echo "+ $(basename "$script")" >&2
    if ! "$script"; then
      code=1
    fi
  done
fi

if [ $code -ne 0 ]; then
  echo "$hook hooks failed" >&2
  exit $code
fi
