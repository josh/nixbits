SCRIPT="$1"
shift

BASH=$(which bash)

x() {
  echo + "$@" >&2
  "$@"
}

x shfmt -w "$SCRIPT"
x shellcheck "$SCRIPT"

if [ -x "$SCRIPT" ]; then
  echo "+" "$SCRIPT" "$@" >&2
  exec "$SCRIPT" "$@"
fi

if [[ $SCRIPT == *.sh || $SCRIPT == *.bash ]]; then
  echo "+" "$BASH" "$SCRIPT" "$@" >&2
  exec "$BASH" "$SCRIPT" "$@"
fi

echo "$SCRIPT is not executable" >&2
exit 1
