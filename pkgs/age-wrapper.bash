#@shebang@
set -o errexit
PATH="@out@/bin:$PATH"
export PATH

args=()
timeout=""

while [ $# -gt 0 ]; do
  case "$1" in
  --identity-command)
    exec 3< <($2)
    args+=("--identity" "/dev/fd/3")
    shift 2
    ;;
  --timeout)
    timeout="$2"
    shift 2
    ;;
  *)
    args+=("$1")
    shift
    ;;
  esac
done

if [ -n "$timeout" ]; then
  exec "@coreutils@/bin/timeout" "$timeout" "@age@/bin/age" "${args[@]}"
else
  exec "@age@/bin/age" "${args[@]}"
fi
