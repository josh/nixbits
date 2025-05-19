if [ $# -eq 0 ] || [ ! -f "$1" ]; then
  echo "usage: ghostty-validate-config <config-file>" >&2
  exit 1
fi

if [ ! -d /Applications/Ghostty.app ]; then
  echo "error: Ghostty is not installed" >&2
  exit 127
fi

exec /Applications/Ghostty.app/Contents/MacOS/ghostty +validate-config --config-file="$1"
