x nix profile wipe-history --older-than "$NIX_PROFILE_WIPE_HISTORY_OLDER_THAN"

used_bytes=$(nix-store-usage)
if [ "$used_bytes" -gt "$NIX_STORE_GC_MAX" ]; then
  free_bytes=$((used_bytes - NIX_STORE_GC_MAX))
  x nix store gc --max "$free_bytes"
fi

x nix store optimise
