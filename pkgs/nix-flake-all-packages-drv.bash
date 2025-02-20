FLAKE_URI="$PWD"

while [ $# -gt 0 ]; do
  case "$1" in
  --system)
    SYSTEM="$2"
    shift 2
    ;;
  -*)
    echo "unknown option: $1" >&2
    exit 1
    ;;
  *)
    FLAKE_URI="$1"
    shift
    ;;
  esac
done

export FLAKE_URI SYSTEM
nix eval --read-only --raw --file "$NIX_EXPR_FILE"
echo ""
