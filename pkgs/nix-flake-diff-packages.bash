if [[ $# -ne 2 ]]; then
  echo "error: expected 2 flakes to compare" >&2
  echo "usage: nix-flake-diff-packages <FLAKE-A> <FLAKE-B>" >&2
  exit 1
fi

jd -color \
  <(nix eval --json "$1#packages") \
  <(nix eval --json "$2#packages")
