system=$(nix eval --raw --impure --expr 'builtins.currentSystem')

drvs_output=$(nix flake show --quiet --json | jq --raw-output --arg system "$system" '.packages[$system] | keys | .[]')
drvs=()
[ -z "$drvs_output" ] || mapfile -t drvs <<<"$drvs_output"

status() { term-status --app nix-flake-rebuild "$@"; }

failed=0
index=0
for drv in "${drvs[@]}"; do
  status --progress $((index * 100 / ${#drvs[@]})) working "Rebuilding $drv"
  index=$((index + 1))
  echo "+ nix build --rebuild .#$drv"
  if ! nix build --no-link ".#$drv"; then
    failed=$((failed + 1))
    continue
  fi
  if ! nix build --rebuild --no-link ".#$drv"; then
    failed=$((failed + 1))
  fi
done

if [ "$failed" -gt 0 ]; then
  echo "error: $failed package(s) failed to rebuild" >&2
  status error "$failed package(s) failed to rebuild"
  exit 1
fi
status "done" "Rebuilt ${#drvs[@]} package(s)"
