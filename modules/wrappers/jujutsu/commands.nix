# Final command packages shared by the JJ module and VCS bundle.
{ config, nixbits }:
{
  jj-init = nixbits.jujutsu-init.override { jjConfiguration = config; };
  jj-pull = nixbits.jujutsu-pull.override { jjConfiguration = config; };
  jj-new-main = nixbits.jujutsu-new-main.override { jjConfiguration = config; };
  jj-new-trunk = nixbits.jujutsu-new-trunk.override { jjConfiguration = config; };
  jj-untracked = nixbits.jujutsu-untracked.override { jjConfiguration = config; };
  jj-wip-changes = nixbits.jujutsu-wip-changes.override { jjConfiguration = config; };
  jj-bookmark-clean = nixbits.jujutsu-bookmark-clean.override { jjConfiguration = config; };
  # Inherit JJ_CONFIG from the caller, including jj-clone.
  jj-git-set-upstream = nixbits.jujutsu-git-set-upstream.override {
    git-config = config.env.GIT_CONFIG_GLOBAL.data;
  };
  jj-clone = nixbits.jujutsu-clone.override { jjConfiguration = config; };
}
