{
  lib,
  writeShellApplication,
  coreutils,
  gh,
  jd-diff-patch,
  nix,
}:
writeShellApplication {
  name = "gh-actions-compare-pr-flake-lockfile";
  runtimeInputs = [
    coreutils
    gh
    jd-diff-patch
    nix
  ];
  inheritPath = false;
  text = builtins.readFile ./gh-actions-compare-pr-flake-lockfile.bash;
  meta = {
    description = "Compare the package outputs of 2 nix flakes for a GitHub Actions PR";
    homepage = "https://github.com/josh/nixbits/blob/main/.github/workflows/flake-lockfile.yml";
    platforms = lib.platforms.all;
  };
}
