{
  writeShellApplication,
  coreutils,
  gh,
  nix-output-monitor,
  nix,
  nvd,
  nixbits,
}:
writeShellApplication {
  name = "nix-profile-upgrade";
  runtimeInputs = [
    coreutils
    gh
    nix
    nix-output-monitor
    nixbits.nix-profile-activate
    nixbits.nix-profile-dry-run
    nvd
  ];
  text = builtins.readFile ./nix-profile-upgrade.bash;
}