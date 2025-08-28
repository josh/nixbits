{
  lib,
  writeShellApplication,
  nix,
  util-linux,
}:
writeShellApplication {
  name = "nix-build-uuid";
  runtimeInputs = [
    nix
    util-linux
  ];
  inheritPath = false;
  text = builtins.readFile ./nix-build-uuid.bash;
  meta = {
    description = "Build a random uuid as a nix package";
    platforms = lib.platforms.all;
  };
}
