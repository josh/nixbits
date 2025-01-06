{
  lib,
  writeShellApplication,
  sqlite,
  jq,
}:
writeShellApplication {
  name = "tccutil-list";
  runtimeEnv = {
    PATH = lib.strings.makeBinPath [
      sqlite
      jq
    ];
  };
  text = builtins.readFile ./tccutil-list.bash;
}
