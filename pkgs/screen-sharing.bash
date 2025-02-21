user=""
password=""
hostname=""
open_opts=()

usage() {
  echo "usage: $0 <tailscale-hostname> [--user|--password|--password-command] [open flags]" >&2
  exit 1
}

if [ -n "$USER" ]; then
  user="$USER"
fi
if [ -n "$SCREEN_SHARING_USER" ]; then
  user="$SCREEN_SHARING_USER"
fi
if [ -n "$SCREEN_SHARING_PASSWORD_COMMAND" ]; then
  password=$(eval "$SCREEN_SHARING_PASSWORD_COMMAND")
fi
if [ -n "$SCREEN_SHARING_PASSWORD" ]; then
  password="$SCREEN_SHARING_PASSWORD"
fi
if [ -n "$SCREEN_SHARING_HOSTNAME" ]; then
  hostname="$SCREEN_SHARING_HOSTNAME"
fi

while [[ $# -gt 0 ]]; do
  case $1 in
  --user)
    user="$2"
    shift 2
    ;;
  --password)
    password="$2"
    shift 2
    ;;
  --password-command)
    password=$(eval "$2")
    shift 2
    ;;
  -h | --help)
    usage
    ;;
  -*)
    open_opts+=("$1")
    shift
    ;;
  *)
    hostname="$1"
    shift
    ;;
  esac
done

if [[ -z $hostname ]]; then
  echo "error: hostname required" >&2
  usage
fi

userinfo="$user"
if [ -n "$password" ]; then
  userinfo="$userinfo:$password"
fi

url="vnc://$userinfo@$hostname?quality=adaptive"

if lan_ip="$(tailscale-lan-ip "$hostname" 2>/dev/null)"; then
  echo "Using high quality direct connection" >&2
  url="vnc://$userinfo@$lan_ip?quality=high&numVirtualDisplays=1"
fi

open "${open_opts[@]}" "$url"
