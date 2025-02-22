{
  lib,
  hostPlatform,
  formats,
  gh,
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
      st = "status --short --branch";
      up = "pull";
    };

    init.defaultBranch = "main";

    push.autoSetupRemote = true;

    credential =
      {
        "https://github.com".helper = "${lib.getExe gh} auth git-credential";
        "https://gist.github.com".helper = "${lib.getExe gh} auth git-credential";
      }
      // (lib.attrsets.optionalAttrs hostPlatform.isMacOS {
        helper = "osxkeychain";
      });
  };
in
config.overrideAttrs {
  meta = {
    description = "git config";
    platforms = lib.platforms.all;
  };
}
