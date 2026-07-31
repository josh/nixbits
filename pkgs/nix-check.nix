{
  lib,
  writeShellApplication,
  nix,
  nixbits,
}:
writeShellApplication {
  name = "nix-check";
  runtimeInputs = [ nix ];
  inheritPath = false;
  text = ''
    # shellcheck source=/dev/null
    source "${nixbits.xtrace}/share/bash/xtrace.bash"
    x-fmt nix flake check --all-systems --show-trace --print-build-logs --keep-going "$@" >&2
    exec nix flake check --all-systems --show-trace --option warn-dirty false --print-build-logs --keep-going "$@"
  '';

  meta = {
    description = "Run nix flake check across all systems";
    platforms = lib.platforms.all;
  };
}
