#@shebang@
set -o errexit
PATH="@out@/bin:$PATH"
export PATH

args=()
while [ $# -gt 0 ]; do
  case "$1" in
  --identity-command)
    if [ $# -lt 2 ]; then
      echo "error: --identity-command requires a value" >&2
      exit 1
    fi
    if ! identity=$($2); then
      echo "error: identity command failed: $2" >&2
      exit 1
    fi
    exec {identity_fd}<<<"$identity"
    args+=("--identity" "/dev/fd/$identity_fd")
    shift 2
    ;;
  *)
    args+=("$1")
    shift
    ;;
  esac
done

exec "@age@/bin/age" "${args[@]}"
