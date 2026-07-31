if [ $# -ne 1 ]; then
  echo "usage: age-keygen-paper <output.pdf>" >&2
  exit 1
fi

output=$(realpath --canonicalize-missing "$1")

tmpdir=$(mktemp -d)
# The EXIT trap alone does not run on an uncaught signal, which would leave
# the plaintext key on disk after a Ctrl-C during pdflatex.
trap 'rm -rf "$tmpdir"' EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM
cd "$tmpdir" || exit 1

set -o xtrace
age-keygen --output key.txt
qrencode --output=qr.png --read-from=key.txt --level=H
pdflatex -jobname=key "$TEX_TEMPLATE"
mv key.pdf "$output"
