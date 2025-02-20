target="$HOME/.ssh/authorized_keys"
url="https://github.com/$GITHUB_USER.keys"
tmp_file="${target}~"

curl --no-progress-meter --fail "$url" --output "$tmp_file"
chmod 600 "$tmp_file"

if [ -f "$target" ] && cmp -s "$tmp_file" "$target"; then
  rm "$tmp_file"
  echo "$target up-to-date" >&2
  exit 0
fi

mv "$tmp_file" "$target"
