{
  writeShellApplication,
  coreutils,
  nix-output-monitor,
  nix,
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
    nixbits.nix-profile-activate
    nixbits.nix-profile-dry-run
    nixbits.nix-profile-run-hooks
    nvd
  ];
  inheritPath = false;
  text = builtins.readFile ./nix-profile-upgrade.bash;

  meta.description = "Upgrade nix profile and run pre/post install hooks";
}
