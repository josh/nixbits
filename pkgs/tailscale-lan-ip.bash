if [ $# -eq 0 ]; then
  echo "usage: tailscale-lan-ip <hostname-or-IP>" >&2
  exit 1
fi

gateway=$(network-gateway)

# FIXME: Don't hardcode 10.0.0.x subnet
if [[ $gateway == "10.0.0.1" ]]; then
  if tailscale ping --c 1 --timeout 1s "$1" 2>/dev/null | grep -Eo '10\.0\.0\.[0-9]+'; then
    exit 0
  else
    echo "Host not reachable from LAN" >&2
    exit 1
  fi
else
  echo "Unknown gateway: $gateway" >&2
  exit 1
fi
