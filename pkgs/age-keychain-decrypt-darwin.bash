usage() {
  echo "usage: $(basename "$0") NAME" >&2
}

while [[ $# -gt 0 ]]; do
  case $1 in
  --filename)
    AGE_KEYCHAIN_FILENAME="$2"
    shift 2
    ;;
  --name)
    AGE_KEYCHAIN_BASENAME="$2"
    shift 2
    ;;
  --dir)
    AGE_KEYCHAIN_DIRNAME="$2"
    shift 2
    ;;
  --label)
    AGE_KEYCHAIN_LABEL="$2"
    shift 2
    ;;
  --recipient)
    AGE_KEYCHAIN_RECIPIENT="$2"
    shift 2
    ;;
  --recipient-command)
    AGE_KEYCHAIN_RECIPIENT_COMMAND="$2"
    shift 2
    ;;
  *)
    AGE_KEYCHAIN_BASENAME="$1"
    shift
    ;;
  esac
done

if [ -z "$AGE_KEYCHAIN_FILENAME" ] && [ -n "$AGE_KEYCHAIN_DIRNAME" ] && [ -n "$AGE_KEYCHAIN_BASENAME" ]; then
  AGE_KEYCHAIN_FILENAME="$AGE_KEYCHAIN_DIRNAME/$AGE_KEYCHAIN_BASENAME.age"
fi

if [ -z "$AGE_KEYCHAIN_FILENAME" ]; then
  usage
  exit 1
elif [ ! -f "$AGE_KEYCHAIN_FILENAME" ]; then
  echo "error: '$AGE_KEYCHAIN_FILENAME' doesn't exist" >&2
  usage
  exit 1
fi

if [ -z "$AGE_KEYCHAIN_RECIPIENT" ] && [ -n "$AGE_KEYCHAIN_RECIPIENT_COMMAND" ]; then
  AGE_KEYCHAIN_RECIPIENT=$($AGE_KEYCHAIN_RECIPIENT_COMMAND)
fi

if [ -n "$AGE_KEYCHAIN_LABEL" ] && [ -n "$AGE_KEYCHAIN_RECIPIENT" ]; then
  if ! security find-generic-password -l "$AGE_KEYCHAIN_LABEL" -a "$AGE_KEYCHAIN_RECIPIENT" >/dev/null 2>&1; then
    echo "No age key found in macOS keychain for '$AGE_KEYCHAIN_LABEL' '$AGE_KEYCHAIN_RECIPIENT'" >&2
    exit 1
  fi
elif [ -n "$AGE_KEYCHAIN_LABEL" ]; then
  if ! security find-generic-password -l "$AGE_KEYCHAIN_LABEL" >/dev/null 2>&1; then
    echo "No age key found in macOS keychain for '$AGE_KEYCHAIN_LABEL'" >&2
    exit 1
  fi
elif [ -n "$AGE_KEYCHAIN_RECIPIENT" ]; then
  if ! security find-generic-password -a "$AGE_KEYCHAIN_RECIPIENT" >/dev/null 2>&1; then
    echo "No age key found in macOS keychain for '$AGE_KEYCHAIN_RECIPIENT'" >&2
    exit 1
  fi
else
  echo "No age key name provided" >&2
  exit 1
fi

age_identity() {
  if [ -n "$AGE_KEYCHAIN_LABEL" ] && [ -n "$AGE_KEYCHAIN_RECIPIENT" ]; then
    security find-generic-password -l "$AGE_KEYCHAIN_LABEL" -a "$AGE_KEYCHAIN_RECIPIENT" -w
  elif [ -n "$AGE_KEYCHAIN_LABEL" ]; then
    security find-generic-password -l "$AGE_KEYCHAIN_LABEL" -w
  elif [ -n "$AGE_KEYCHAIN_RECIPIENT" ]; then
    security find-generic-password -a "$AGE_KEYCHAIN_RECIPIENT" -w
  else
    exit 2
  fi
}

age --decrypt --identity <(age_identity) <"$AGE_KEYCHAIN_FILENAME"
