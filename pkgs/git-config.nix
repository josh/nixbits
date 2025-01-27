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

    init.defaultBranch = "main";

    push.autoSetupRemote = true;
  };
in
config.overrideAttrs {
  allowedReferences = [ ];
  allowedRequisites = [ ];

  outputHash = "sha256-BIIctweTzwQ84dO3kYXr+1/dMQaDTnymffo/KIaNZWw=";
  outputHashAlgo = "sha256";
  outputHashMode = "nar";

  meta = {
    description = "git config";
    platforms = lib.platforms.all;
  };
}
