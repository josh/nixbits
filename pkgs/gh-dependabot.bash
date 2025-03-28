graphql() {
  gh api graphql --raw-field query="$1" 2>/dev/null || true
}

urls() {
  echo "https://github.com/pulls?q=is:open+is:pr+owner:josh"
  graphql '
    query {
      viewer {
        repositories(first: 100, isFork: false, isArchived: false) {
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
  ' |
    jq --raw-output '
      .data.viewer.repositories.nodes |
      map(select(.main.target.file != null) |
      "\(.url)/network/updates") |
      .[]
    '
}

if [[ ${1:-} == "--open" ]]; then
  urls | xargs -n 1 open
else
  urls
fi
