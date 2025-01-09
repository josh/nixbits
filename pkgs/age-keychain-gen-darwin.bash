usage() {
  echo "usage: age-keychain-gen [--label LABEL] [--se] [--check] [--force]" >&2
  exit 1
}

label="age"
service="age"
check=false
force=false

while [[ $# -gt 0 ]]; do
  case $1 in
  --label)
    label="$2"
    shift 2
    ;;
  --se)
    service="age-plugin-se"
    shift
    ;;
  --check)
    check=true
    shift
    ;;
  --force)
    force=true
    shift
    ;;
  *)
    echo "unknown $1" >&2
    usage
    ;;
  esac
done

if [ "$check" = true ]; then
  if ! security find-generic-password -l "$label" >/dev/null 2>&1; then
    echo "'$label' age key missing from Keychain" >&2
    exit 1
  fi
  exit 0
elif [ "$force" = true ]; then
  :
elif security find-generic-password -l "$label" >/dev/null 2>&1; then
  echo "'$label' age key is already in Keychain" >&2
  exit 0
fi

tmpdir=$(mktemp -d)
keypath="$tmpdir/key.txt"

if [ "$service" = "age-plugin-se" ]; then
  age-plugin-se keygen --access-control none --output "$keypath"
  public_key=$(age-plugin-se recipients --input "$keypath")
else
  age-keygen --output "$keypath"
  public_key=$(age-keygen -y "$keypath")
fi

private_key=$(tail -n 1 <"$keypath")
shred --remove "$keypath"

security add-generic-password \
  -a "$public_key" \
  -s "$service" \
  -l "$label" \
  -w "$private_key"
