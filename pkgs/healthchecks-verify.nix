{
  lib,
  writeShellApplication,
  coreutils,
  curl,
  findutils,
  gnugrep,
  jq,
  runtimeEnv ? { },
}:
writeShellApplication {
  name = "healthchecks-verify";
  runtimeEnv = {
    PATH = lib.strings.makeBinPath [
      coreutils
      curl
      findutils
      gnugrep
      jq
    ];
  } // (lib.attrsets.filterAttrs (_name: value: value != null) runtimeEnv);
  text = builtins.readFile ./healthchecks-verify.bash;
  meta = {
    description = "Verify local healthchecks slugs exist on healthchecks.io server";
    platforms = lib.platforms.all;
  };
}
