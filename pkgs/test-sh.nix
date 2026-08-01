{
  lib,
  writeShellApplication,
  bash,
  shellcheck,
  shfmt,
}:
writeShellApplication {
  name = "test-sh";
  runtimeEnv = {
    "BASH" = lib.getExe bash;
    "SHELLCHECK" = lib.getExe shellcheck;
    "SHFMT" = lib.getExe shfmt;
  };
  text = builtins.readFile ./test-sh.bash;
  meta = {
    description = "Format, lint and test shell script";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
