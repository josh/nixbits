{
  writeShellApplication,
  coreutils,
  nix,
}:
writeShellApplication {
  name = "nix-profile-run-hooks";
  runtimeInputs = [
    coreutils
    nix
  ];
  inheritPath = false;
  text = builtins.readFile ./nix-profile-run-hooks.bash;

  meta.description = "Run hooks for nix profile";
}
