{
  buildEnv,
  nixbits,
  # keep-sorted start
  bash,
  coreutils,
  gh,
  git,
  gnutar,
  gzip,
  jq,
  nix,
  which,
  # keep-sorted end
}:
let
  inherit (nixbits) gtar;
in
buildEnv {
  name = "gh-actions-runner-env";
  paths = [
    # keep-sorted start
    bash
    coreutils
    gh
    git
    gnutar
    gtar
    gzip
    jq
    nix
    which
    # keep-sorted end
  ];
  pathsToLink = [ "/bin" ];
}
