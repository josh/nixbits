{
  lib,
  writeShellApplication,
  gh,
  gnugrep,
  nix,
}:
writeShellApplication {
  name = "check-nix-config-github-token";
  runtimeEnv = {
    PATH = lib.strings.makeBinPath [
      gh
      gnugrep
      nix
    ];
  };
  text = builtins.readFile ./check-nix-config-github-token.bash;
}
