flake_uri="${1:-$PWD}"

system=$(nix eval --raw --impure --expr 'builtins.currentSystem')

checks() {
  nix flake show --all-systems --json "${flake_uri}" |
    jq --raw-output \
      --arg system "${system}" \
      --arg prefix "${flake_uri}#checks.${system}." \
      '.checks[$system] | keys | .[] | $prefix + .'
}

nix flake check

checks | nix path-info --json --stdin | jq --compact-output 'to_entries[] | {key: .key} + .value' | while read -r json; do
  key=$(echo "$json" | jq --raw-output '.key')
  narSize=$(echo "$json" | jq --raw-output '.narSize')
  reference_count=$(echo "$json" | jq --raw-output '.references | length')
  if [ "$reference_count" -ne 0 ]; then
    echo "WARN: $key has multiple references" >&2
    echo "$json" | jq
  elif [ "$narSize" -gt 200 ]; then
    echo "WARN: $key has large narSize: $narSize" >&2
    echo "$json" | jq
  fi
done
