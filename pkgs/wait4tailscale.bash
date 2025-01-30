is_online() {
  tailscale status --json | jq --exit-status '.Self.Online' >/dev/null
}

for delay in 1 1 10 30; do
  if is_online; then
    exit 0
  fi
  sleep "$delay"
done

while ! is_online; do
  sleep 60
done
