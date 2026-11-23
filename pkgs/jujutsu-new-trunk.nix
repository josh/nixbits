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
  name = "jj-new-trunk";
  runtimeInputs = [
    jujutsu
  ];
  inheritPath = false;
  runtimeEnv = commandEnv jjConfiguration // {
    XTRACE_PATH = nixbits.xtrace;
  };
  text = builtins.readFile ./jujutsu-new-trunk.bash;

  meta = {
    description = "Fetch remotes then create new change from trunk()";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
