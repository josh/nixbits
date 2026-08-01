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
    description = "Compare flake outputs between a PR base and head lockfile";
    homepage = "https://github.com/josh/nixbits/blob/main/.github/workflows/flake-lockfile.yml";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
