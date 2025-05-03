#@shebang@
set -o errexit
PATH="@out@/bin:$PATH"
export PATH

args=()
while [ $# -gt 0 ]; do
  case "$1" in
  --identity-command)
    exec 3< <($2)
    args+=("--identity" "/dev/fd/3")
    shift 2
    ;;
  *)
    args+=("$1")
    shift
    ;;
  esac
done

exec "@age@/bin/age" "${args[@]}"
