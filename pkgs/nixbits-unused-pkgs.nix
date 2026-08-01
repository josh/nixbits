{
  lib,
  writeShellApplication,
  coreutils,
  jq,
  nixbits,
}:
writeShellApplication {
  name = "nixbits-unused-pkgs";
  runtimeInputs = [
    coreutils
    jq
    nixbits.gh
  ];
  inheritPath = false;
  runtimeEnv = {
    NIXBITS_PKG_NAMES = builtins.concatStringsSep " " (builtins.attrNames nixbits);
  };
  text = builtins.readFile ./nixbits-unused-pkgs.bash;

  meta = {
    description = "List nixbits packages unused by dependent repositories";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
