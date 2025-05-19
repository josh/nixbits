if [ $# -eq 0 ] || [ ! -f "$1" ]; then
  echo "usage: ghostty-validate-config <config-file>"
  exit 1
fi

exec ghostty +validate-config --config-file="$1"
