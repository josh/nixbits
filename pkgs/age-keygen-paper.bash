if [ $# -ne 1 ]; then
  echo "usage: age-keygen-paper <output.pdf>" >&2
  exit 1
fi

output="$1"

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT
cd "$tmpdir" || exit 1

set -o xtrace
age-keygen --output key.txt
qrencode --output=qr.png --read-from=key.txt --level=H
pdflatex -jobname=key "$TEX_TEMPLATE"
mv key.pdf "$output"
