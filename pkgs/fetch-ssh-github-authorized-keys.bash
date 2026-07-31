target="$HOME/.ssh/authorized_keys"
url="https://github.com/$GITHUB_USER.keys"
tmp_file="${target}~"

umask 077
mkdir -p "$HOME/.ssh"

curl --no-progress-meter --fail "$url" --output "$tmp_file"

if [ -f "$target" ] && cmp -s "$tmp_file" "$target"; then
  rm "$tmp_file"
  echo "$target up-to-date" >&2
  exit 0
fi

mv "$tmp_file" "$target"
echo "$target updated" >&2
