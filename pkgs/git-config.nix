{
  lib,
  runCommand,
  git,
  nixbits,
  wlibEvalPackage,
}:
let
  wrapper = nixbits.git;
  config = runCommand "git-config" { } ''
    cp ${wrapper.configuration.constructFiles.gitconfig} "$out"
  '';
in
config.overrideAttrs {
  passthru.tests = {
    defaults = runCommand "test-git-config-defaults" { nativeBuildInputs = [ git ]; } ''
      cmp ${config} ${wrapper.configuration.constructFiles.gitconfig}
      test "$(git --no-pager config get --file ${config} user.name)" = "Joshua Peek"
      test "$(git --no-pager config get --file ${config} user.email)" = "josh@users.noreply.github.com"
      test "$(git --no-pager config get --file ${config} init.defaultBranch)" = main
      for host in github.com gist.github.com; do
        printf '%s\n' "" "${lib.getExe nixbits.gh} auth git-credential" >expected
        git --no-pager config get --file ${config} --all "credential.https://$host.helper" >actual
        cmp expected actual
      done
      touch "$out"
    '';

    module-settings =
      let
        custom = wlibEvalPackage [
          ../modules/wrappers/git.nix
          {
            settings.user.name = lib.mkForce "Module User";
            settings.credential."https://git.example.com".helper = [
              ""
              "module-helper"
            ];
          }
        ];
      in
      runCommand "test-git-wrapper-module-settings" { } ''
        export HOME="$TMPDIR/home"
        mkdir -p "$HOME"
        export GIT_CONFIG_NOSYSTEM=1
        unset GIT_CONFIG_GLOBAL
        test "$(${lib.getExe custom} config get user.name)" = "Module User"
        test "$(${lib.getExe custom} config get user.email)" = "josh@users.noreply.github.com"
        test "$(${lib.getExe custom} config get --url=https://git.example.com credential.helper)" = module-helper
        touch "$out"
      '';
  };

  meta = {
    description = "Configuration for the Git version control system";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
