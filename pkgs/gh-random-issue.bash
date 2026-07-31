# usage: gh-random-issue [--open]

_issue_url() {
  local count
  count=$(gh api 'search/issues' \
    --method GET \
    --field 'q=is:open user:josh' \
    --field 'per_page=1' \
    --jq '.total_count')

  if [ "$count" -eq 0 ]; then
    echo "error: no open issues found" >&2
    return 1
  fi

  # The search API serves at most the first 1000 results.
  if [ "$count" -gt 1000 ]; then
    count=1000
  fi

  gh api 'search/issues' \
    --method GET \
    --field 'q=is:open user:josh' \
    --field 'per_page=1' \
    --field "page=$((RANDOM % count + 1))" \
    --jq '.items[0].html_url'
}

if [[ ${1:-} == "--open" ]]; then
  url=$(_issue_url)
  xdg-open "$url"
else
  _issue_url
fi
