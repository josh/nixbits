{
  git,
  runCommand,
  testers,
  wlibEvalPackage,
}:
wlibEvalPackage (
  { config, wlib, ... }:
  {
    imports = [ wlib.wrapperModules.git ];
    package = git;
    drv.pname = "git-bot";
    drv.name = "git-bot-${git.version}";

    settings.user = {
      name = "github-actions[bot]";
      email = "41898282+github-actions[bot]@users.noreply.github.com";
    };

    passthru.tests = {
      version = testers.testVersion {
        package = config.wrapper;
        command = "git version";
        inherit (git) version;
      };
      user = runCommand "test-git-user" { nativeBuildInputs = [ config.wrapper ]; } ''
        test "$(git config get user.name)" = 'github-actions[bot]'
        touch "$out"
      '';
      commit-author = runCommand "test-git-commit-author" { nativeBuildInputs = [ config.wrapper ]; } ''
        git init --initial-branch main
        git commit --allow-empty --message initial
        test "$(git log -1 --format='%an <%ae>')" = 'github-actions[bot] <41898282+github-actions[bot]@users.noreply.github.com>'
        touch "$out"
      '';
    };
  }
)
