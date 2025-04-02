set -o errexit
set -o nounset
set -o pipefail

if [ $# -eq 0 ]; then
  echo "usage: x [-q|-s] [--] command [args...]" >&2
  exit 1
fi

quiet=false
silent=false

case $1 in
-q)
  quiet=true
  shift
  ;;
-s)
  silent=true
  shift
  ;;
esac

[ "$1" == "--" ] && shift

if [ "$quiet" = true ]; then
  x-quiet "$@"
elif [ "$silent" = true ]; then
  x-silent "$@"
else
  x "$@"
fi
