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
  name = "jj-pull";
  runtimeInputs = [
    jujutsu
  ];
  inheritPath = false;
  runtimeEnv = commandEnv jjConfiguration // {
    XTRACE_PATH = nixbits.xtrace;
  };
  text = builtins.readFile ./jujutsu-pull.bash;

  meta = {
    description = "Pull jj git remote";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
