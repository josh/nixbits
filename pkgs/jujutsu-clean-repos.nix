{
  lib,
  stdenv,
  writeShellApplication,
  bash,
  coreutils,
  darwin,
  findutils,
  gnugrep,
  gum,
  jujutsu,
  trash-cli,
  nixbits,
}:
let
  trash = if stdenv.hostPlatform.isDarwin then darwin.trash else trash-cli;
in
writeShellApplication {
  name = "jj-clean-repos";
  runtimeInputs = [
    bash
    coreutils
    findutils
    gnugrep
    gum
    jujutsu
    nixbits.jujutsu-untracked
    nixbits.jujutsu-wip-changes
    trash
  ];
  inheritPath = false;
  runtimeEnv = {
    GIT_CONFIG_GLOBAL = nixbits.git-config;
    JJ_CONFIG = nixbits.jujutsu-config;
  };
  text = builtins.readFile ./jujutsu-clean-repos.bash;

  meta = {
    description = "Interactively audit and trash fully pushed repositories in a projects directory";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
