{
  lib,
  writeShellApplication,
  nix,
  nixbits,
}:
writeShellApplication {
  name = "nix-flake-update-jj-main";
  runtimeInputs = [
    nix
    nixbits.git
    nixbits.jujutsu
  ];
  inheritPath = false;
  runtimeEnv = {
    XTRACE_PATH = nixbits.xtrace;
  };
  text = builtins.readFile ./nix-flake-update-jj-main.bash;
  meta = {
    description = "Create a new jujutsu change, update nix flake input and move main forward on success";
    platforms = lib.platforms.all;
  };
}
