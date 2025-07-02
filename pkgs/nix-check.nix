{
  writeShellApplication,
  nix,
  nixbits,
}:
writeShellApplication {
  name = "nix-check";
  runtimeInputs = [ nix ];
  text = ''
    # shellcheck source=/dev/null
    source "${nixbits.xtrace}/share/bash/xtrace.bash"
    x-fmt nix flake check --all-systems --show-trace --print-build-logs --keep-going "$@" >&2
    exec nix flake check --all-systems --show-trace --option warn-dirty false --print-build-logs --keep-going "$@"
  '';
}
