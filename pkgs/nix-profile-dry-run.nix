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
  inheritPath = false;
  text = builtins.readFile ./nix-profile-dry-run.bash;

  meta.description = "Build new nix profile without modifying the current one";
}
