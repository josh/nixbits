{
  lib,
  writeShellApplication,
  coreutils,
  nix,
  nix-output-monitor,
  nvd,
  nixbits,
}:
let
  inherit (nixbits) gh;
in
writeShellApplication {
  name = "nix-profile-upgrade";
  runtimeInputs = [
    coreutils
    gh
    nix
    nix-output-monitor
    (nixbits.nix-profile-activate.override { inherit nix; })
    (nixbits.nix-profile-dry-run.override { inherit nix; })
    nixbits.nix-profile-run-hooks
    nvd
  ];
  inheritPath = false;
  text = builtins.readFile ./nix-profile-upgrade.bash;

  meta = {
    description = "Upgrade nix profile and run pre/post install hooks";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
