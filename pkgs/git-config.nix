{
  lib,
  nixbits,
  runCommand,
}:
runCommand "git-config"
  {
    meta = {
      description = "Configuration for the Git version control system";
      license = lib.licenses.mit;
      platforms = lib.platforms.all;
    };
  }
  ''
    cp ${nixbits.git.configuration.constructFiles.gitconfig} "$out"
  ''
