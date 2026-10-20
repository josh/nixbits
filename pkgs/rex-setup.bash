# shellcheck source=/dev/null
source "$XTRACE_PATH/share/bash/xtrace.bash"

export PATH="$PATH:/usr/bin"

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

terminfo_plan="$("$rex" terminfo setup --dry-run --json --autostart=false 2>/dev/null || true)"
if ! jq --exit-status '.entry.status == "already installed" and .guard.status == "already current"' <<<"$terminfo_plan" >/dev/null 2>&1; then
  x "$rex" terminfo setup --autostart=false || echo "warn: rex terminfo setup failed" >&2
fi

skill_plan="$("$rex" skill setup --dry-run --json --autostart=false 2>/dev/null || true)"
if ! jq --exit-status 'all(.steps[]; .change == "unchanged" or .change == "skipped")' <<<"$skill_plan" >/dev/null 2>&1; then
  x "$rex" skill setup --autostart=false || echo "warn: rex skill setup failed" >&2
fi
