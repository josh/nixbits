SCRIPT="$1"
shift

echo + shfmt -w "$SCRIPT" >&2
"$SHFMT" -w "$SCRIPT"

echo + shellcheck "$SCRIPT" >&2
"$SHELLCHECK" "$SCRIPT"

if [ -x "$SCRIPT" ]; then
  echo + "$SCRIPT" "$@" >&2
  exec "$SCRIPT" "$@"
fi

if [[ $SCRIPT == *.sh || $SCRIPT == *.bash ]]; then
  echo + bash "$SCRIPT" "$@" >&2
  exec "$BASH" "$SCRIPT" "$@"
fi

echo "$SCRIPT is not executable" >&2
exit 1
