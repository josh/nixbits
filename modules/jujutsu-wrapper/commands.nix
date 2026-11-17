# Shared by the module defaults and the package compatibility adapter.
{ config, nixbits }:
let
  git-config = config.env.GIT_CONFIG_GLOBAL.data;
  sharedConfig = {
    inherit git-config;
    jujutsu-config = config.configFile.path;
  };
in
{
  jj-init = nixbits.jujutsu-init.override sharedConfig;
  jj-pull = nixbits.jujutsu-pull.override sharedConfig;
  jj-new-main = nixbits.jujutsu-new-main.override sharedConfig;
  jj-untracked = nixbits.jujutsu-untracked.override sharedConfig;
  jj-wip-changes = nixbits.jujutsu-wip-changes.override sharedConfig;
  jj-bookmark-clean = nixbits.jujutsu-bookmark-clean.override sharedConfig;
  # Inherit JJ_CONFIG from the caller, including jj-clone.
  jj-git-set-upstream = nixbits.jujutsu-git-set-upstream.override { inherit git-config; };
  jj-clone = nixbits.jujutsu-clone.override (
    sharedConfig
    // {
      jujutsu-git-set-upstream = config.commands.jj-git-set-upstream;
    }
  );
}
