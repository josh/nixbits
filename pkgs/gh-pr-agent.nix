{
  lib,
  writeShellApplication,
  claude-code,
  codex,
  coreutils,
  git,
  gnugrep,
  gum,
  jujutsu,
  nixbits,
}:
let
  inherit (nixbits) gh;
in
writeShellApplication {
  name = "gh-pr-agent";
  runtimeInputs = [
    # keep-sorted start
    claude-code
    codex
    coreutils
    gh
    git
    gnugrep
    gum
    jujutsu
    nixbits.jujutsu-clone
    # keep-sorted end
  ];
  inheritPath = true;
  runtimeEnv = {
    GIT_CONFIG_GLOBAL = nixbits.git-config;
    JJ_CONFIG = nixbits.jujutsu-config;
    XTRACE_PATH = nixbits.xtrace;
  };
  text = builtins.readFile ./gh-pr-agent.bash;

  meta = {
    description = "Check out a GitHub pull request with jj and launch a coding agent";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
