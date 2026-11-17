{
  lib,
  writeShellApplication,
  wlibEvalPackage,
  git,
  gnugrep,
  jujutsu,
  nixbits,
  jjConfiguration ? nixbits.jujutsu.configuration,
}:
let
  commandEnv = import ../modules/wrappers/jujutsu/command-env.nix {
    inherit lib git wlibEvalPackage;
  };
in
writeShellApplication {
  name = "jj-bookmark-clean";
  runtimeInputs = [
    gnugrep
    jujutsu
  ];
  inheritPath = false;
  runtimeEnv = commandEnv jjConfiguration // {
    XTRACE_PATH = nixbits.xtrace;
  };
  text = builtins.readFile ./jujutsu-bookmark-clean.bash;

  meta = {
    description = "Clean up merged jj push-* bookmarks";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
