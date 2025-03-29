RESTIC_REPOSITORY="${RESTIC_REPOSITORY:-}"
unset RESTIC_PASSWORD_FILE
unset RESTIC_PASSWORD_COMMAND
RESTIC_AGE_IDENTITY_COMMAND="${RESTIC_AGE_IDENTITY_COMMAND:-}"
RESTIC_AGE_IDENTITY_FILE="${RESTIC_AGE_IDENTITY_FILE:-}"
RESTIC_AGE_RECIPIENT="${RESTIC_AGE_RECIPIENT:-}"

restic_init_args=()
while [[ $# -gt 0 ]]; do
  case $1 in
  --repo)
    RESTIC_REPOSITORY="$2"
    export RESTIC_REPOSITORY
    restic_init_args+=("--repo" "$2")
    shift 2
    ;;
  --password-file)
    echo "error: --password-file is not supported" >&2
    exit 1
    ;;
  --password-command)
    echo "error: --password-command is not supported" >&2
    exit 1
    ;;
  --recipient)
    RESTIC_AGE_RECIPIENT="$2"
    export RESTIC_AGE_RECIPIENT
    shift 2
    ;;
  --identity-file)
    RESTIC_AGE_IDENTITY_FILE="$2"
    export RESTIC_AGE_IDENTITY_FILE
    shift 2
    ;;
  --identity-command)
    RESTIC_AGE_IDENTITY_COMMAND="$2"
    export RESTIC_AGE_IDENTITY_COMMAND
    shift 2
    ;;
  *)
    restic_init_args+=("$1")
    shift
    ;;
  esac
done

x() {
  (
    set -o xtrace
    "$@"
  )
}

RESTIC_PASSWORD_FILE=$(mktemp)
openssl rand -base64 32 >"$RESTIC_PASSWORD_FILE"
export RESTIC_PASSWORD_FILE

x restic init "${restic_init_args[@]}"
orig_key_id=$(restic key list --json | jq --raw-output 'map(.id)[0]')

if [ -z "$RESTIC_AGE_RECIPIENT" ]; then
  if [ -n "$RESTIC_AGE_IDENTITY_FILE" ]; then
    RESTIC_AGE_RECIPIENT=$(age-keygen -y "$RESTIC_AGE_IDENTITY_FILE")
  elif [ -n "$RESTIC_AGE_IDENTITY_COMMAND" ]; then
    RESTIC_AGE_RECIPIENT=$(eval "$RESTIC_AGE_IDENTITY_COMMAND" | age-keygen -y)
  fi
fi

x restic-age-key add --recipient "$RESTIC_AGE_RECIPIENT"
restic-age-key password >"$RESTIC_PASSWORD_FILE"

x restic key remove "$orig_key_id"
rm -f "$RESTIC_PASSWORD_FILE"
