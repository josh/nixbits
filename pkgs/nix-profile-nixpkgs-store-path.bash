nix-profile-nixpkgs-uri | while read -r uri; do
  nix flake archive --json "$uri" | jq --raw-output '.path'
done
