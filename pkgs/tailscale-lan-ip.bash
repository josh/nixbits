if [ $# -eq 0 ]; then
  echo "usage: tailscale-lan-ip <hostname-or-IP>" >&2
  exit 1
fi

# All three RFC 1918 ranges: 10/8, 172.16/12, 192.168/16.
lan_ip_pattern="via (10\.[0-9]+\.[0-9]+\.[0-9]+|172\.(1[6-9]|2[0-9]|3[01])\.[0-9]+\.[0-9]+|192\.168\.[0-9]+\.[0-9]+):[0-9]+"
# The first replies often arrive via DERP; tailscale ping keeps going until
# a direct path is negotiated, so give it a few attempts.
if output=$(tailscale ping -c 5 --timeout 1s "$1" 2>/dev/null) && [[ $output =~ $lan_ip_pattern ]]; then
  echo "${BASH_REMATCH[1]}"
  exit 0
else
  echo "Host not reachable from LAN" >&2
  exit 1
fi
