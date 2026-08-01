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
    description = "Update a nix flake input in a new jujutsu change and advance main";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
