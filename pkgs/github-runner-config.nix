{
  lib,
  stdenv,
  writeShellApplication,
  coreutils,
  gnugrep,
  nixbits,
  github-runner,
  github-runner-root ? null,
  github-runner-url ? null,
  github-runner-use-gh-token ? true,
  github-runner-group ? null,
  github-runner-name ? null,
  github-runner-labels ? [ stdenv.hostPlatform.system ],
  github-runner-work ? null,
  github-runner-ephemeral ? false,
}:
let
  inherit (nixbits) gh;
  labels =
    if github-runner-labels != null && github-runner-labels != [ ] then
      (builtins.concatStringsSep "," github-runner-labels)
    else
      null;
in
writeShellApplication {
  name = "github-runner-config";
  runtimeInputs = [
    coreutils
    gh
    gnugrep
    nixbits.github-runner-config-remove
  ];
  inheritPath = false;
  runtimeEnv = {
    GITHUB_RUNNER_PATH = github-runner;
  }
  // (lib.attrsets.optionalAttrs (github-runner-root != null) {
    RUNNER_ROOT = github-runner-root;
  })
  // (lib.attrsets.optionalAttrs (github-runner-url != null) {
    RUNNER_URL = github-runner-url;
  })
  // (lib.attrsets.optionalAttrs github-runner-use-gh-token {
    RUNNER_USE_GH_TOKEN = true;
  })
  // (lib.attrsets.optionalAttrs (github-runner-group != null) {
    RUNNER_RUNNERGROUP = github-runner-group;
  })
  // (lib.attrsets.optionalAttrs (github-runner-name != null) {
    RUNNER_NAME = github-runner-name;
  })
  // (lib.attrsets.optionalAttrs (labels != null) {
    RUNNER_LABELS = labels;
  })
  // (lib.attrsets.optionalAttrs (github-runner-work != null) {
    RUNNER_WORK = github-runner-work;
  })
  // (lib.attrsets.optionalAttrs github-runner-ephemeral {
    RUNNER_EPHEMERAL = github-runner-ephemeral;
  });
  text = builtins.readFile ./github-runner-config.bash;

  meta = {
    description = "Configure GitHub Actions runner";
    platforms = lib.platforms.all;
  };
}
