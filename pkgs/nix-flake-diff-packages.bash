usage() {
  echo "usage: nix-flake-diff-packages [--changes|--no-changes] <FLAKE-A> <FLAKE-B>" >&2
}

flake_a=""
flake_b=""
changes=false

while [[ $# -gt 0 ]]; do
  case "$1" in
  --help)
    usage
    exit 0
    ;;
  --changes)
    changes=true
    shift
    ;;
  --no-changes)
    changes=false
    shift
    ;;
  *)
    if [ -z "${flake_a}" ]; then
      flake_a="$1"
    elif [ -z "${flake_b}" ]; then
      flake_b="$1"
    else
      echo "error: unexpected argument: $1" >&2
      usage
      exit 1
    fi
    shift
    ;;
  esac
done

if [ -z "${flake_a}" ] || [ -z "${flake_b}" ]; then
  echo "error: expected 2 flakes to compare" >&2
  usage
  exit 1
fi

a_out=$(mktemp)
b_out=$(mktemp)

trap 'rm -f "$a_out" "$b_out"' EXIT

nix eval --json "${flake_a}#packages" >"$a_out" &
pid_a=$!

nix eval --json "${flake_b}#packages" >"$b_out" &
pid_b=$!

status_a=0
status_b=0
wait $pid_a || status_a=$?
wait $pid_b || status_b=$?

if [ $status_a -ne 0 ]; then
  echo "error: failed to evaluate ${flake_a}#packages" >&2
  exit $status_a
fi

if [ $status_b -ne 0 ]; then
  echo "error: failed to evaluate ${flake_b}#packages" >&2
  exit $status_b
fi

if [ "$changes" == true ]; then
  # jd exits 0 when equal, 1 when different, 2 on error. Invert the first
  # two so "changes present" is success, but keep errors as errors.
  status=0
  jd -color "$a_out" "$b_out" || status=$?
  case "$status" in
  0) exit 1 ;;
  1) exit 0 ;;
  *) exit "$status" ;;
  esac
else
  jd -color "$a_out" "$b_out"
fi
