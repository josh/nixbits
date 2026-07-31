if [ -n "${1:-}" ]; then
  if [ -e "$1" ]; then
    echo "error: $1 already exists" >&2
    exit 1
  fi
  cat "$TEMPLATE_PATH" >"$1"
  chmod +x "$1"
else
  cat "$TEMPLATE_PATH"
fi
