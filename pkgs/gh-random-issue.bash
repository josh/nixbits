# usage: gh-random-issue [--open]

_issue_url() {
  gh api 'search/issues' \
    --method GET \
    --field 'q=is:open user:josh' \
    --field 'per_page=200' \
    --jq ".items | .[$RANDOM % length] | .html_url"
}

if [[ ${1:-} == "--open" ]]; then
  xdg-open "$(_issue_url)"
else
  _issue_url
fi
