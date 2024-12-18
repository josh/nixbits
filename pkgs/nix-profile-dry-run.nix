{
  writeShellApplication,
  coreutils,
  nix,
}:
writeShellApplication {
  name = "nix-profile-dry-run";
  runtimeInputs = [
    coreutils
    nix
  ];
  text = builtins.readFile ./nix-profile-dry-run.bash;
}
