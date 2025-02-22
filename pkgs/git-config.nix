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
      ca = "commit --all --verbose";
      ci = "commit --verbose";
      co = "checkout";
      ct = "checkout --track";
      patch = "!git --no-pager diff --no-color";
      st = "status --short --branch";
      up = "pull";
    };

    init.defaultBranch = "main";

    fetch.prune = true;
    push.autoSetupRemote = true;

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
