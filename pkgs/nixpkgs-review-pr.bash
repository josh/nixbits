systems="aarch64-darwin aarch64-linux x86_64-linux"
shell_flag="--no-shell"
result_flag="--post-result"
args=()

while [[ $# -gt 0 ]]; do
  case "$1" in
  --dry-run)
    result_flag="--print-result"
    shift
    ;;
  --systems)
    systems="$2"
    shift 2
    ;;
  --shell)
    shell_flag=""
    shift
    ;;
  *)
    args+=("$1")
    shift
    ;;
  esac
done

if [ -d "$HOME/Developer/nixpkgs" ]; then
  cd "$HOME/Developer/nixpkgs" || true
fi

exec nixpkgs-review pr \
  --systems "$systems" \
  $shell_flag \
  $result_flag \
  "${args[@]}"
