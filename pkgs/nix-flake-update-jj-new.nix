{
  lib,
  writeShellApplication,
  nix,
  nixbits,
}:
writeShellApplication {
  name = "nix-flake-update-jj-new";
  runtimeInputs = [
    nix
    nixbits.git
    nixbits.jujutsu
  ];
  inheritPath = false;
  runtimeEnv = {
    XTRACE_PATH = nixbits.xtrace;
  };
  text = builtins.readFile ./nix-flake-update-jj-new.bash;
  meta = {
    description = "Create a new jujutsu change, update nix flake input and create a new bookmark on success";
    platforms = lib.platforms.all;
  };
}
