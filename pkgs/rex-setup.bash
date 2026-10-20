# shellcheck source=/dev/null
source "$XTRACE_PATH/share/bash/xtrace.bash"

app_rex="$HOME/Library/Application Support/com.superlogical.rex/RexServer/Versions/Current/Rex Server.app/Contents/MacOS/rex"

if command -v rex >/dev/null; then
  rex="$(command -v rex)"
elif [ -x "${REX_BIN_DIR:-}/rex" ]; then
  rex="$REX_BIN_DIR/rex"
elif [ -x "$app_rex" ]; then
  rex="$app_rex"
else
  exit 0
fi

x "$rex" terminfo setup --autostart=false || echo "warn: rex terminfo setup failed" >&2
x "$rex" skill setup --autostart=false || echo "warn: rex skill setup failed" >&2
