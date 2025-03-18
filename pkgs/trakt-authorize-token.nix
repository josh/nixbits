{
  lib,
  writeShellApplication,
  curl,
  gnugrep,
  gnused,
  jq,
  netcat,
  nixbits,
}:
writeShellApplication {
  name = "trakt-authorize-token";
  runtimeEnv = {
    PATH = lib.makeBinPath [
      curl
      gnugrep
      gnused
      jq
      netcat
      nixbits.darwin.open
    ];
  };
  text = builtins.readFile ./trakt-authorize-token.bash;
  meta = {
    description = "Generate Trakt OAuth access and refresh tokens";
    platforms = lib.platforms.darwin;
  };
}
