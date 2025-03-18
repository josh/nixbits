usage() {
  echo "usage: trakt-id-from-url [--client-id TRAKT_CLIENT_ID] <URL>" >&2
}

url=""
TRAKT_CLIENT_ID="${TRAKT_CLIENT_ID:-}"

while [[ $# -gt 0 ]]; do
  case "$1" in
  --client-id)
    TRAKT_CLIENT_ID="$2"
    shift 2
    ;;
  --help)
    usage
    exit 0
    ;;
  *)
    if [ -z "$url" ]; then
      url="$1"
      shift
    else
      echo "error: unexpected argument: $1" >&2
      usage
      exit 1
    fi
    ;;
  esac
done

if [[ -z $TRAKT_CLIENT_ID ]]; then
  echo "error: missing TRAKT_CLIENT_ID" >&2
  exit 1
fi

trakt_id() {
  curl --silent --show-error --fail \
    --url "https://api.trakt.tv${1}" \
    --header "Content-Type: application/json" \
    --header "trakt-api-version: 2" \
    --header "trakt-api-key: ${TRAKT_CLIENT_ID}" | jq --raw-output '.ids.trakt'
}

if [[ $url =~ https://trakt\.tv/shows/([^/]+)/seasons/([^/]+)/episodes/([^/]+) ]]; then
  SHOW_SLUG="${BASH_REMATCH[1]}"
  SEASON_NUMBER="${BASH_REMATCH[2]}"
  EPISODE_NUMBER="${BASH_REMATCH[3]}"
  trakt_id "/shows/${SHOW_SLUG}/seasons/${SEASON_NUMBER}/episodes/${EPISODE_NUMBER}"
elif [[ $url =~ https://trakt\.tv/shows/([^/]+) ]]; then
  SLUG="${BASH_REMATCH[1]}"
  trakt_id "/shows/${SLUG}"
elif [[ $url =~ https://trakt\.tv/movies/([^/]+) ]]; then
  SLUG="${BASH_REMATCH[1]}"
  trakt_id "/movies/${SLUG}"
else
  echo "error: unknown url: $url" >&2
  exit 1
fi
