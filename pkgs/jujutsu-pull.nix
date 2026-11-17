{
  lib,
  writeShellApplication,
  wlibEvalPackage,
  git,
  jujutsu,
  nixbits,
  git-config ? nixbits.git-config,
  jjConfiguration ? nixbits.jujutsu.configuration,
  jujutsu-config ? null,
}:
let
  # Only bypass a wrapper identical to the stock Git wrapper with these settings.
  # Other wrappers may run hooks, supply flags, or select a different Git.
  settingsOnlyGit = wlibEvalPackage [
    ../modules/wrappers/git.nix
    {
      constructFiles.gitconfig.content = lib.mkForce jjConfiguration.gitWrapper.configuration.constructFiles.gitconfig.content;
    }
  ];
  pullConfiguration =
    if jjConfiguration.gitWrapper.outPath == settingsOnlyGit.outPath then
      jjConfiguration.apply {
        # Prefer native Git over the JJ module default, preserving explicit JJ settings.
        settings.git.executable-path = lib.mkOverride 999 (lib.getExe git);
      }
    else
      jjConfiguration;
in
writeShellApplication {
  name = "jj-pull";
  runtimeInputs = [
    jujutsu
  ];
  inheritPath = false;
  runtimeEnv = {
    GIT_CONFIG_GLOBAL = git-config;
    JJ_CONFIG = if jujutsu-config == null then pullConfiguration.configFile.path else jujutsu-config;
    XTRACE_PATH = nixbits.xtrace;
  };
  text = builtins.readFile ./jujutsu-pull.bash;

  meta = {
    description = "Pull jj git remote";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
