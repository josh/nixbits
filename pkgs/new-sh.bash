if [ -n "${1:-}" ]; then
  cat "$TEMPLATE_PATH" >"$1"
  chmod +x "$1"
else
  cat "$TEMPLATE_PATH"
fi
