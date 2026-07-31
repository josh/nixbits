{
  writeShellApplication,
  coreutils,
}:
writeShellApplication {
  name = "nix-profile-run-hooks";
  runtimeInputs = [
    coreutils
  ];
  inheritPath = false;
  text = builtins.readFile ./nix-profile-run-hooks.bash;

  meta.description = "Run hooks for nix profile";
}
