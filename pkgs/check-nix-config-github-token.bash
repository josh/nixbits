if ! gh auth token >/dev/null 2>&1; then
  echo "ERROR: gh not authenticated" >&2
  exit 1
fi
GITHUB_TOKEN=$(gh auth token)

if nix config show access-tokens | grep --quiet "github.com=$GITHUB_TOKEN"; then
  exit 0
fi

if nix config show access-tokens | grep --quiet "github.com="; then
  echo "warn: nix config github.com access token out of date" >&2
  exit 0
fi

echo "ERROR: nix config missing github.com access token" >&2
echo "" >&2
echo "Add the following to /etc/nix/nix.conf:" >&2
echo "access-tokens = github.com=$GITHUB_TOKEN" >&2
exit 1
