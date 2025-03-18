usage() {
  echo "usage: trakt-authorize-token [--client-id TRAKT_CLIENT_ID] [--client-secret TRAKT_CLIENT_SECRET]" >&2
}

TRAKT_CLIENT_ID="${TRAKT_CLIENT_ID:-}"
TRAKT_CLIENT_SECRET="${TRAKT_CLIENT_SECRET:-}"

while [[ $# -gt 0 ]]; do
  case "$1" in
  --client-id)
    TRAKT_CLIENT_ID="$2"
    shift 2
    ;;
  --client-secret)
    TRAKT_CLIENT_SECRET="$2"
    shift 2
    ;;
  --help)
    usage
    exit 0
    ;;
  *)
    echo "error: unknown option: $1" >&2
    usage
    exit 1
    ;;
  esac
done

if [[ -z $TRAKT_CLIENT_ID ]]; then
  echo "error: missing TRAKT_CLIENT_ID" >&2
  exit 1
fi

if [[ -z $TRAKT_CLIENT_SECRET ]]; then
  echo "error: missing TRAKT_CLIENT_SECRET" >&2
  exit 1
fi

open_authorize_url() {
  open "https://api.trakt.tv/oauth/authorize?response_type=code&client_id=${TRAKT_CLIENT_ID}&redirect_uri=http://localhost:3000/oauth2callback&scope="
}

ok() {
  echo "HTTP/1.1 200 OK"
  echo "Connection: close"
  echo "Content-Length: 2"
  echo ""
  echo "OK"
}

wait_for_code() {
  ok |
    nc -l 3000 |
    grep --extended-regexp --only-matching --regexp 'code=[a-z0-9]+' |
    sed 's/code=//'
}

open_authorize_url
CODE=$(wait_for_code)
[ -n "$CODE" ]

curl --fail --show-error --silent \
  --request POST \
  --url "https://api.trakt.tv/oauth/token" \
  --data "code=${CODE}" \
  --data "client_id=${TRAKT_CLIENT_ID}" \
  --data "client_secret=${TRAKT_CLIENT_SECRET}" \
  --data "redirect_uri=http://localhost:3000/oauth2callback" \
  --data "grant_type=authorization_code" | jq
