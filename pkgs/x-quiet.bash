if [ $# -eq 0 ]; then
  echo "usage: x-quiet command [args...]" >&2
  exit 1
fi

[ "$1" == "--" ] && shift

if out=$("$BASH" -o xtrace -c '"$@"' bash "$@" 2>&1); then
  exit 0
else
  code=$?
  echo "$out" >&2
  exit $code
fi
