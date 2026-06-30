# Unsubscribes by default; --dry-run only previews.
apply=true

while [[ $# -gt 0 ]]; do
  case "$1" in
  --dry-run) apply=false ;;
  -h | --help)
    echo "usage: gh-subscriptions-prune [--dry-run]"
    exit 0
    ;;
  *)
    echo "unknown option: $1" >&2
    exit 1
    ;;
  esac
  shift
done

OWNER="josh"
export OWNER

# Subscribed issues/PRs in OWNER's repos. /issues?filter=subscribed lists every
# thread whose viewer subscription is active -- i.e. the subscriptions web page --
# across all repos including your own, regardless of notification activity. Each
# item carries node_id (for the unsubscribe mutation), state, and pull_request.
# --paginate walks all pages; --jq runs per page; env.OWNER avoids interpolation.
subscribed_threads() {
  gh api --paginate '/issues?filter=subscribed&state=all&per_page=100' \
    --jq '.[]
      | select(.repository.owner.login == env.OWNER)
      | select(.state == "closed")
      | [.node_id, (if .pull_request then "pr" else "issue" end), .html_url]
      | @tsv'
}

while IFS=$'\t' read -r node_id kind url; do
  if $apply; then
    echo "+ unsubscribe $kind $url" >&2
    # shellcheck disable=SC2016 # $id is a GraphQL variable, not a shell one
    gh api graphql \
      --raw-field query='mutation($id: ID!) {
        updateSubscription(input: {subscribableId: $id, state: UNSUBSCRIBED}) {
          subscribable { id viewerSubscription }
        }
      }' \
      --raw-field id="$node_id" >/dev/null
  else
    printf '%s\t%s\n' "$kind" "$url"
  fi
done < <(subscribed_threads)
