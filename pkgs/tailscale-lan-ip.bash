if [ $# -eq 0 ]; then
  echo "usage: tailscale-lan-ip <hostname-or-IP>" >&2
  exit 1
fi

lan_ip_pattern="via (10\.[0-9]+\.[0-9]+\.[0-9]+|192\.168\.[0-9]+\.[0-9]+):[0-9]+"
if output=$(tailscale ping --c 1 --timeout 1s "$1" 2>/dev/null) && [[ $output =~ $lan_ip_pattern ]]; then
  echo "${BASH_REMATCH[1]}"
  exit 0
else
  echo "Host not reachable from LAN" >&2
  exit 1
fi
