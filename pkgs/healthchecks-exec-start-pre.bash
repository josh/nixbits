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
  "${HC_PING_URL:-@pingURL@}/${PING_KEY:-@pingKey@}/${CHECK_SLUG:-@slug@}/start?rid=$rid"
