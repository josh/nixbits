{
  lib,
  hostPlatform,
  formats,
  diff-so-fancy,
  gh,
  less,
}:
let
  gitIni = formats.gitIni { };
  config = gitIni.generate "git-config" {
    user = {
      name = "Joshua Peek";
      email = "josh@users.noreply.github.com";
    };

    alias = {
      b = "branch";
      ba = "branch --all";
      ca = "commit --all";
      ci = "commit";
      co = "checkout";
      ct = "checkout --track";
      patch = "!git --no-pager diff --no-color";
      st = "status --short --branch";
      up = "pull";
    };

    # Improve listing branches
    # <https://blog.gitbutler.com/how-git-core-devs-configure-git/#listing-branches>
    column.ui = "auto";
    branch.sort = "-committerdate";

    # Improve listing tags
    # <https://blog.gitbutler.com/how-git-core-devs-configure-git/#listing-tags>
    tag.sort = "version:refname";

    # Set default branch
    # <https://blog.gitbutler.com/how-git-core-devs-configure-git/#default-branch>
    init.defaultBranch = "main";

    # Better diff
    # <https://blog.gitbutler.com/how-git-core-devs-configure-git/#better-diff>
    diff = {
      algorithm = "histogram";
      colorMoved = "plain";
      mnemonicPrefix = true;
      renames = true;
    };

    # Better pushing
    # <https://blog.gitbutler.com/how-git-core-devs-configure-git/#better-pushing>
    push = {
      default = "simple"; # (default since 2.0)
      autoSetupRemote = true;
      followTags = true;
    };

    # Better pulling
    # <https://blog.gitbutler.com/how-git-core-devs-configure-git/#better-pulling>
    pull = {
      rebase = true;
    };

    # Better fetching
    # <https://blog.gitbutler.com/how-git-core-devs-configure-git/#better-fetching>
    fetch = {
      prune = true;
      pruneTags = true;
      all = true;
    };

    # Autocorrect prompting
    # <https://blog.gitbutler.com/how-git-core-devs-configure-git/#autocorrect-prompting>
    help.autocorrect = "prompt";

    # Commit with diffs
    # <https://blog.gitbutler.com/how-git-core-devs-configure-git/#commit-with-diffs>
    commit.verbose = true;

    # Reuse recorded resolutions
    # <https://blog.gitbutler.com/how-git-core-devs-configure-git/#reuse-recorded-resolutions>
    rerere = {
      enabled = true;
      autoupdate = true;
    };

    # Slightly nicer rebase
    # <https://blog.gitbutler.com/how-git-core-devs-configure-git/#slightly-nicer-rebase>
    rebase = {
      autoSquash = true;
      autoStash = true;
      updateRefs = true;
    };

    # Better merge conflicts
    # <https://blog.gitbutler.com/how-git-core-devs-configure-git/#better-merge-conflicts>
    # merge.conflictstyle = "zdiff3";

    credential =
      {
        "https://github.com".helper = "${lib.getExe gh} auth git-credential";
        "https://gist.github.com".helper = "${lib.getExe gh} auth git-credential";
      }
      // (lib.attrsets.optionalAttrs hostPlatform.isMacOS {
        helper = "osxkeychain";
      });

    # diff-so-fancy
    core.pager = "${lib.getExe diff-so-fancy} | ${lib.getExe less} --tabs=4 -RF";
    core.interactive.diffFilter = "${lib.getExe diff-so-fancy} --patch";
    diff-so-fancy.markEmptyLines = false;
  };
in
config.overrideAttrs {
  meta = {
    description = "git config";
    platforms = lib.platforms.all;
  };
}
