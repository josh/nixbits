code_search_count() {
  gh api \
    --method GET \
    /search/code \
    --field "q=user:josh language:nix $1" \
    --jq '.total_count'
}

request_count=0
flush_newline=false
throttle() {
  request_count=$((request_count + 1))
  if [ $((request_count % 8)) -eq 0 ]; then
    printf "." >&2
    flush_newline=true
    sleep 60
  else
    sleep 1
  fi
}

for pkg in $NIXBITS_PKG_NAMES; do
  count=$(code_search_count "nixbits.$pkg")
  throttle

  # Consumers may use "inherit (nixbits) foo;" instead of "nixbits.foo".
  # The quoted phrase matches adjacently; bare terms would match any file
  # that merely mentions inherit, nixbits, and the name separately.
  if [ "$count" -eq 0 ]; then
    count=$(code_search_count "\"inherit (nixbits)\" $pkg")
    throttle
  fi

  if [ "$count" -eq 0 ]; then
    if [ "$flush_newline" = true ]; then
      echo "" >&2
    fi
    echo "pkgs/${pkg}.nix may not be used" >&2
    flush_newline=false
  fi
done

if [ "$flush_newline" = true ]; then
  echo "" >&2
fi
