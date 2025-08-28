code_search_count() {
  gh api \
    --method GET \
    /search/code \
    --field "q=user:josh language:nix nixbits.$1" \
    --jq '.total_count'
}

request_count=0
flush_newline=false
for pkg in $NIXBITS_PKG_NAMES; do
  count=$(code_search_count "$pkg")
  if [ "$count" -eq 0 ]; then
    if [ "$flush_newline" = true ]; then
      echo "" >&2
    fi
    echo "pkgs/${pkg}.nix may not be used" >&2
    flush_newline=false
  fi

  request_count=$((request_count + 1))
  if [ $((request_count % 8)) -eq 0 ]; then
    printf "." >&2
    flush_newline=true
    sleep 60
  else
    sleep 1
  fi
done
