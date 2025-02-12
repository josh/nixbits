{
  lib,
  writeShellApplication,
  coreutils,
  bash,
  shellcheck,
  shfmt,
  which,
}:
writeShellApplication {
  name = "test-sh";
  runtimeEnv = {
    PATH = lib.strings.makeBinPath [
      bash
      coreutils
      shellcheck
      shfmt
      which
    ];
  };
  text = builtins.readFile ./test-sh.bash;

  meta = {
    description = "Format, lint and test shell script";
    platforms = lib.platforms.all;
  };
}
