target="$HOME/.ssh/authorized_keys"
url="https://github.com/$GITHUB_USER.keys"
tmp_file="${target}~"

umask 077
mkdir -p "$HOME/.ssh"

curl --no-progress-meter --fail "$url" --output "$tmp_file"

# GitHub returns 200 with an empty body for accounts without SSH keys.
# Installing that would truncate authorized_keys and lock out remote access.
if [ ! -s "$tmp_file" ]; then
  rm -f "$tmp_file"
  echo "error: $url returned no keys" >&2
  exit 1
fi

if [ -f "$target" ] && cmp -s "$tmp_file" "$target"; then
  rm "$tmp_file"
  echo "$target up-to-date" >&2
  exit 0
fi

mv "$tmp_file" "$target"
echo "$target updated" >&2
