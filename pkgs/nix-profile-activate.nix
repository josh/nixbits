{
  writeShellApplication,
  coreutils,
  nixbits,
}:
writeShellApplication {
  name = "nix-profile-activate";
  runtimeInputs = [
    coreutils
    nixbits.nix-profile-run-hooks
  ];
  inheritPath = false;
  text = builtins.readFile ./nix-profile-activate.bash;

  meta.description = "Activate target nix profile";
}
