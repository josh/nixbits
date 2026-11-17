{
  lib,
  nixbits,
  runCommand,
}:
runCommand "git-bot-config"
  {
    allowedReferences = [ ];
    allowedRequisites = [ ];
    meta = {
      description = "Git configuration for a GitHub Actions bot identity";
      license = lib.licenses.mit;
      platforms = lib.platforms.all;
    };
  }
  ''
    cp ${nixbits.git-bot.configuration.constructFiles.gitconfig} "$out"
  ''
