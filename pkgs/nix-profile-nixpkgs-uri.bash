nix profile list --json | jq --raw-output '.elements | map(.url) | .[]' | while read -r uri; do
  nix flake metadata --json "$uri" | jq --raw-output '
    .locks.nodes.root.inputs.nixpkgs as $nixpkgs |
    .locks.nodes[$nixpkgs].locked |
    "\(.type):\(.owner)/\(.repo)/\(.rev)?narHash=\(.narHash | @uri)"
  '
done
