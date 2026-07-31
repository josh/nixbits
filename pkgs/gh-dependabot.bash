# shellcheck disable=SC2016 # $cursor is a GraphQL variable, not a shell one
graphql() {
  gh api graphql --raw-field query='
    query($cursor: String) {
      viewer {
        repositories(
          first: 100
          after: $cursor
          isFork: false
          isArchived: false
          ownerAffiliations: [OWNER]
        ) {
          pageInfo {
            hasNextPage
            endCursor
          }
          nodes {
            url
            main: defaultBranchRef {
              target {
                ... on Commit {
                  file(path: ".github/dependabot.yml") {
                    __typename
                  }
                }
              }
            }
          }
        }
      }
    }
  ' --field cursor="$1"
}

urls() {
  echo "https://github.com/pulls?q=is:open+is:pr+owner:josh"

  local cursor="null" response
  while :; do
    # gh exits non-zero when the response carries any GraphQL error, even
    # benign per-repo ones like unresolvable dependabot.yml paths on empty
    # repositories. Tolerate those, but stop if no data came back at all.
    response=$(graphql "$cursor") || true
    if [ "$(jq --raw-output '.data.viewer.repositories | type' <<<"$response")" != "object" ]; then
      echo "error: failed to list repositories" >&2
      exit 1
    fi
    jq --raw-output '
      .data.viewer.repositories.nodes |
      map(select(.main.target.file != null) |
      "\(.url)/network/updates") |
      .[]
    ' <<<"$response"

    if [ "$(jq --raw-output '.data.viewer.repositories.pageInfo.hasNextPage' <<<"$response")" != "true" ]; then
      break
    fi
    cursor=$(jq --raw-output '.data.viewer.repositories.pageInfo.endCursor' <<<"$response")
    if [ -z "$cursor" ] || [ "$cursor" = "null" ]; then
      break
    fi
  done
}

if [[ ${1:-} == "--open" ]]; then
  urls | xargs -n 1 xdg-open
else
  urls
fi
