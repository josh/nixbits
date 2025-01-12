system=$(nix eval --raw --impure --expr 'builtins.currentSystem')

nix flake show --quiet --json 2>/dev/null |
  jq --raw-output --arg system "$system" '.packages[$system] | keys | .[]' |
  while read -r drv; do
    echo "+ nix build --rebuild --no-link .#$drv"
    nix build --rebuild --no-link ".#$drv"
  done
