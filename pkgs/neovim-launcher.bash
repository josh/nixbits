if [[ -n ${REX_SESSION:-} && -n ${REX_BLOCK:-} && -t 0 && -t 1 ]]; then
  for arg; do
    case "$arg" in
    --) break ;;
    - | -h | --help | --version | -v | --api-info | --headless | --embed | --listen | --server | --remote* | -es | -Es | -e | -E | -l | -s | --startuptime)
      exec "$NVIM_BIN" "$@"
      ;;
    esac
  done
  # A bare filename can also be a neorex subcommand.
  case "${1:-}" in
  help | daemon | pane | debug-*) set -- "./$1" "${@:2}" ;;
  esac
  exec "$NEOREX_BIN" "$@"
fi
exec "$NVIM_BIN" "$@"
