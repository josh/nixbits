ping_key="${PING_KEY:-@pingKey@}"
check_slug="${CHECK_SLUG:-@slug@}"

# An empty key or slug would ping a nonexistent .../key//start URL, and the
# resulting curl --fail would abort the unit this script instruments.
if [ -z "$ping_key" ]; then
  echo "error: PING_KEY is not set" >&2
  exit 1
fi
if [ -z "$check_slug" ]; then
  echo "error: CHECK_SLUG is not set" >&2
  exit 1
fi

rid=""
if [ -n "$INVOCATION_ID" ]; then
  rid="${INVOCATION_ID:0:8}-${INVOCATION_ID:8:4}-${INVOCATION_ID:12:4}-${INVOCATION_ID:16:4}-${INVOCATION_ID:20:12}"
fi

@curl@/bin/curl \
  --fail \
  --silent \
  --show-error \
  --max-time 10 \
  --retry 5 \
  --output /dev/null \
  "${HC_PING_URL:-@pingURL@}/$ping_key/$check_slug/start?rid=$rid"
