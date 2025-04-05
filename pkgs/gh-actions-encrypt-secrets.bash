if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "error: Current directory is not a git repository" >&2
  exit 1
fi

secrets_tmpfile=$(mktemp -t gh-actions-secrets.XXXXXX)
recipients_tmpfile=$(mktemp -t age-recipients.XXXXXX)
trap 'rm -f "$secrets_tmpfile" "$recipients_tmpfile"' EXIT
chmod 600 "$secrets_tmpfile"
chmod 600 "$recipients_tmpfile"

if [ -n "${SECRETS_JSON:-}" ]; then
  echo "$SECRETS_JSON" >"$secrets_tmpfile"
  unset SECRETS_JSON
else
  cat >"$secrets_tmpfile"
fi

if [ -n "${AGE_RECIPIENT:-}" ]; then
  echo "$AGE_RECIPIENT" >>"$recipients_tmpfile"
fi
if [ -n "${AGE_RECIPIENTS:-}" ]; then
  echo "$AGE_RECIPIENTS" >>"$recipients_tmpfile"
fi

if [ ! -s "$recipients_tmpfile" ]; then
  echo "error: no recipients given" >&2
  exit 1
fi

jq --raw-output 'keys[]' <"$secrets_tmpfile" | while read -r name; do
  if [ "$name" = "github_token" ]; then
    continue
  fi
  value=$(jq --raw-output ".$name" <"$secrets_tmpfile")

  hash=$(echo -n "$value" | cat - "$recipients_tmpfile" | sha256sum | cut -d' ' -f1)
  if [ -f "$name.hash" ] && [ "$(cat "$name.hash")" = "$hash" ]; then
    echo "skip $name" >&2
    continue
  fi

  echo "encrypt $name" >&2
  echo -n "$value" | age --encrypt --armor --recipients-file "$recipients_tmpfile" --output "$name.age"
  echo "$hash" >"$name.hash"
  git add "$name.age" "$name.hash"
done

for file in *.age *.hash; do
  if [ "$file" = "*.age" ] || [ "$file" = "*.hash" ]; then
    continue
  fi
  name="${file%.*}"
  if jq --exit-status ".$name == null" <"$secrets_tmpfile" >/dev/null; then
    echo "remove $file" >&2
    git rm "$file"
  fi
done

committed=false
if git commit --message "Encrypt secrets"; then
  committed=true
fi

GITHUB_OUTPUT="${GITHUB_OUTPUT:-/dev/stdout}"
echo "committed=$committed" | tee -a "$GITHUB_OUTPUT"
