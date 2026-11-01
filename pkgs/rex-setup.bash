# shellcheck source=/dev/null
source "$XTRACE_PATH/share/bash/xtrace.bash"

usage() {
  echo "usage: rex-setup [--dry-run]" >&2
}

dry_run=false

for arg in "$@"; do
  case "$arg" in
  "--dry-run")
    dry_run=true
    ;;
  *)
    usage
    exit 1
    ;;
  esac
done

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

"$rex" version >/dev/null 2>&1 || exit 0

terminfo_plan="$("$rex" terminfo setup --dry-run --json --autostart=false 2>/dev/null || true)"
if ! jq --exit-status '.entry.status == "already installed" and (.guard.status == "already current" or .external_guard_in_effect == true)' <<<"$terminfo_plan" >/dev/null 2>&1; then
  x-dry-run $dry_run -- "$rex" terminfo setup --autostart=false || echo "warn: rex terminfo setup failed" >&2
fi

skill_plan="$("$rex" skill setup --dry-run --json --autostart=false 2>/dev/null || true)"
if ! jq --exit-status 'all(.steps[]; .change == "unchanged" or .change == "skipped")' <<<"$skill_plan" >/dev/null 2>&1; then
  x-dry-run $dry_run -- "$rex" skill setup --autostart=false || echo "warn: rex skill setup failed" >&2
fi
