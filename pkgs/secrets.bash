if [ $# -eq 0 ]; then
  echo "usage: secret <name>" >&2
  exit 1
fi

if [ -z "$AGE_IDENTITY_COMMAND" ]; then
  echo "error: no age identity configured; set ageIdentity" >&2
  exit 1
fi

name="$1"
input=""

IFS=':' read -ra secret_paths <<<"$SECRETS_PATH"
for path in "${secret_paths[@]}"; do
  [ -f "$path/$name.age" ] || continue
  input="$path/$name.age"
  break
done

if [ -z "$input" ]; then
  echo "error: no secret '$name'" >&2
  exit 1
fi

age --decrypt --identity-command "$AGE_IDENTITY_COMMAND" "$input" | ensure-newline
