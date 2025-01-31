{
  lib,
  formats,
}:
let
  gitIni = formats.gitIni { };
  config = gitIni.generate "git-bot-config" {
    user = {
      name = "github-actions[bot]";
      email = "41898282+github-actions[bot]@users.noreply.github.com";
    };
  };
in
config.overrideAttrs {
  allowedReferences = [ ];
  allowedRequisites = [ ];

  outputHash = "sha256-aAKnHbMxoZimJsgp977f0o0Q5ago3EABf7+MTM2g52E=";
  outputHashAlgo = "sha256";
  outputHashMode = "nar";

  meta = {
    description = "github actions bot git config";
    platforms = lib.platforms.all;
  };
}
