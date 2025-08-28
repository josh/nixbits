UUID=$(uuidgen)
NIX_EXPR="(import <nixpkgs> {}).runCommand \"uuid\" {} \"echo $UUID >\$out\""

set -o xtrace
nix build \
  --no-link \
  --print-out-paths \
  --impure \
  --expr "$NIX_EXPR"
