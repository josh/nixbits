{
  lib,
  wlibEvalPackage,
  git,
}:
jjConfiguration:
let
  # Only bypass a wrapper identical to the stock Git wrapper with these settings.
  # Other wrappers may run hooks, supply flags, or select a different Git.
  settingsOnlyGit = wlibEvalPackage [
    ../git.nix
    {
      constructFiles.gitconfig.content = lib.mkForce jjConfiguration.gitWrapper.configuration.constructFiles.gitconfig.content;
    }
  ];
  commandConfiguration =
    if jjConfiguration.gitWrapper.outPath == settingsOnlyGit.outPath then
      jjConfiguration.apply {
        # Prefer native Git over the JJ module default, preserving explicit JJ settings.
        settings.git.executable-path = lib.mkOverride 999 (lib.getExe git);
      }
    else
      jjConfiguration;
in
{
  GIT_CONFIG_GLOBAL = jjConfiguration.env.GIT_CONFIG_GLOBAL.data;
  JJ_CONFIG = commandConfiguration.configFile.path;
}
