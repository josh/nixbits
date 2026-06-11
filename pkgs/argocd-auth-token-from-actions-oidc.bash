: "${ARGOCD_SERVER:?ARGOCD_SERVER must be set (e.g. argocd.example.ts.net)}"

connector_id="${ARGOCD_OIDC_CONNECTOR_ID:-github-actions}"
server_url="https://${ARGOCD_SERVER}"

request_actions_id_token() {
  curl --silent --fail --show-error \
    "${ACTIONS_ID_TOKEN_REQUEST_URL}&audience=${server_url}" \
    --header "Accept: application/json; api-version=2.0" \
    --header "Content-Type: application/json" \
    --header "Authorization: Bearer ${ACTIONS_ID_TOKEN_REQUEST_TOKEN}" |
    jq --raw-output '.value'
}

request_dex_token() {
  curl --silent --fail --show-error \
    "${server_url}/api/dex/token" \
    --user argo-cd-cli: \
    --data-urlencode "connector_id=${connector_id}" \
    --data-urlencode "grant_type=urn:ietf:params:oauth:grant-type:token-exchange" \
    --data-urlencode "scope=openid email profile federated:id" \
    --data-urlencode "requested_token_type=urn:ietf:params:oauth:token-type:access_token" \
    --data-urlencode "subject_token=$1" \
    --data-urlencode "subject_token_type=urn:ietf:params:oauth:token-type:id_token" |
    jq --raw-output '.access_token'
}

actions_id_token=$(request_actions_id_token)
dex_token=$(request_dex_token "${actions_id_token}")

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  {
    echo "actions-id-token=${actions_id_token}"
    echo "dex-token=${dex_token}"
  } >>"${GITHUB_OUTPUT}"
else
  echo "${dex_token}"
fi
