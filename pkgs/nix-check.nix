{
  lib,
  writeShellApplication,
  nix,
  nixbits,
}:
writeShellApplication {
  name = "nix-check";
  runtimeInputs = [
    nix
    nixbits.term-status
  ];
  inheritPath = false;
  text = ''
    # shellcheck source=/dev/null
    source "${nixbits.xtrace}/share/bash/xtrace.bash"
    x-fmt nix flake check --all-systems --show-trace --print-build-logs --keep-going "$@" >&2
    exec term-status --app nix-check --msg "Checking flake" -- nix flake check --all-systems --show-trace --option warn-dirty false --print-build-logs --keep-going "$@"
  '';

  meta = {
    description = "Run nix flake check across all systems";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
