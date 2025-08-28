human=false
while [[ $# -gt 0 ]]; do
  case $1 in
  -h | --human)
    human=true
    shift
    ;;
  *)
    echo "usage: $0 [-h]" >&2
    exit 1
    ;;
  esac
done

if df -k /nix &>/dev/null; then
  bytes_used=$(df -k /nix 2>/dev/null | awk '/\/nix/ {print $3 * 1024}')
else
  echo "warn: using 'nix path-info' to compute usage" >&2
  bytes_used=$(nix path-info --json --all 2>/dev/null | jq --raw-output 'map(.narSize // 0) | add')
fi

if [[ $human == true ]]; then
  numfmt --to=iec-i --suffix=B <<<"$bytes_used"
else
  echo "$bytes_used"
fi
