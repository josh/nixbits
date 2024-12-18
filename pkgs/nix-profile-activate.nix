{
  writeShellApplication,
  coreutils,
}:
writeShellApplication {
  name = "nix-profile-activate";
  runtimeInputs = [
    coreutils
  ];
  text = builtins.readFile ./nix-profile-activate.bash;
}
