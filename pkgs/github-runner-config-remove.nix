{
  lib,
  writeShellApplication,
  coreutils,
  gnugrep,
  gh,
  github-runner,
  github-runner-root ? null,
  github-runner-use-gh-token ? true,
}:
writeShellApplication {
  name = "github-runner-config-remove";
  runtimeEnv =
    {
      PATH = lib.strings.makeBinPath [
        coreutils
        gh
        gnugrep
      ];
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
