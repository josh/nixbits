{
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
  runtimeEnv = {
    NIXBITS_PKG_NAMES = builtins.concatStringsSep " " (builtins.attrNames nixbits);
  };
  inheritPath = false;
  text = builtins.readFile ./nixbits-unused-pkgs.bash;
}
