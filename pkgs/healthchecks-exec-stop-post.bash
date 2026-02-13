rid=""
if [ -n "$INVOCATION_ID" ]; then
  rid="${INVOCATION_ID:0:8}-${INVOCATION_ID:8:4}-${INVOCATION_ID:12:4}-${INVOCATION_ID:16:4}-${INVOCATION_ID:20:12}"
fi

status="fail"
if [ "$SERVICE_RESULT" == "success" ]; then
  status="0"
elif [[ $SERVICE_RESULT == "exit-code" && $EXIT_STATUS =~ ^[0-9]{1,3}$ ]]; then
  status="$EXIT_STATUS"
fi

log() {
  if [ -n "$INVOCATION_ID" ]; then
    @systemd@/bin/journalctl _SYSTEMD_INVOCATION_ID="$INVOCATION_ID" --no-pager --output=cat
  else
    echo "journald logs unavailable; missing INVOCATION_ID"
  fi
}

log | @curl@/bin/curl \
  --fail \
  --silent \
  --show-error \
  --max-time 10 \
  --retry 5 \
  --data-binary '@-' \
  --header 'Content-Type: text/plain' \
  --output /dev/null \
  "${HC_PING_URL:-@pingURL@}/${PING_KEY:-@pingKey@}/${CHECK_SLUG:-@slug@}/$status?rid=$rid"
