{
  lib,
  formats,
}:
let
  gitIni = formats.gitIni { };
  config = gitIni.generate "git-config" {
    user = {
      name = "Joshua Peek";
      email = "josh@users.noreply.github.com";
    };

    alias = {
      co = "checkout";
      ci = "commit --verbose";
    };

    init.defaultBranch = "main";

    push.autoSetupRemote = true;
  };
in
config.overrideAttrs {
  allowedReferences = [ ];
  allowedRequisites = [ ];

  outputHash = "sha256-7+clCQl7JWtZZGWwfMGb4QTMQQCx0R7C55OmqnMIynU=";
  outputHashAlgo = "sha256";
  outputHashMode = "nar";

  meta = {
    description = "git config";
    platforms = lib.platforms.all;
  };
}
