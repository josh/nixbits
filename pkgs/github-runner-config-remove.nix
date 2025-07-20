{
  lib,
  writeShellApplication,
  coreutils,
  gnugrep,
  github-runner,
  github-runner-root ? null,
  github-runner-use-gh-token ? true,
  nixbits,
}:
let
  inherit (nixbits) gh;
in
writeShellApplication {
  name = "github-runner-config-remove";
  runtimeInputs = [
    coreutils
    gh
    gnugrep
  ];
  inheritPath = false;
  runtimeEnv = {
    GITHUB_RUNNER_PATH = github-runner;
  }
  // (lib.attrsets.optionalAttrs (github-runner-root != null) {
    RUNNER_ROOT = github-runner-root;
  })
  // (lib.attrsets.optionalAttrs github-runner-use-gh-token {
    RUNNER_USE_GH_TOKEN = true;
  });
  text = builtins.readFile ./github-runner-config-remove.bash;

  meta = {
    description = "Unconfigure GitHub Actions runner";
    platforms = lib.platforms.all;
  };
}
