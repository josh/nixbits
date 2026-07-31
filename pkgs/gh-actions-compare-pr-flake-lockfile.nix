{
  lib,
  writeShellApplication,
  coreutils,
  gh,
  gnugrep,
  jd-diff-patch,
}:
writeShellApplication {
  name = "gh-actions-compare-pr-flake-lockfile";
  runtimeInputs = [
    coreutils
    gh
    gnugrep
    jd-diff-patch
    # Use nix from environment
  ];
  inheritPath = true;
  text = builtins.readFile ./gh-actions-compare-pr-flake-lockfile.bash;
  meta = {
    description = "Compare the package and check outputs of 2 nix flakes for a GitHub Actions PR";
    homepage = "https://github.com/josh/nixbits/blob/main/.github/workflows/flake-lockfile.yml";
    platforms = lib.platforms.all;
  };
}
