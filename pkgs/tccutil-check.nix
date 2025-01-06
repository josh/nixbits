{
  lib,
  writeShellApplication,
  sqlite,
  jq,
}:
writeShellApplication {
  name = "tccutil-check";
  runtimeEnv = {
    PATH = lib.strings.makeBinPath [
      sqlite
      jq
    ];
  };
  text = builtins.readFile ./tccutil-check.bash;
}
