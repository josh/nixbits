{
  lib,
  writeShellApplication,
  wlibEvalPackage,
  git,
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
  name = "jj-new-main";
  runtimeInputs = [
    jujutsu
  ];
  inheritPath = false;
  runtimeEnv = commandEnv jjConfiguration;
  text = builtins.readFile ./jujutsu-new-main.bash;

  meta = {
    description = "Fetch origin then create new change from main@origin";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
