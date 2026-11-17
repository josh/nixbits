{
  lib,
  runCommand,
  git,
  nixbits,
  wlibEvalPackage,
  extraCredentials ? { },
}:
let
  wrapper = wlibEvalPackage [
    ../modules/git-wrapper.nix
    {
      # Preserve the old shallow merge: replace each supplied credential entry,
      # including all of a host's fields and its ordered helper list.
      settings.credential = lib.mapAttrs (_name: value: lib.mkForce value) extraCredentials;
    }
  ];
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

    credential-overrides =
      let
        custom = nixbits.git-config.override {
          extraCredentials = {
            helper = [
              ""
              "global-helper"
            ];
            "https://github.com".useHttpPath = true;
            "https://gist.github.com".helper = [
              ""
              "first-helper"
              "second-helper"
            ];
            "https://git.example.com" = {
              helper = [
                ""
                "example-helper"
              ];
              useHttpPath = true;
            };
          };
        };
      in
      runCommand "test-git-config-credential-overrides" { nativeBuildInputs = [ git ]; } ''
        # A replacement host entry must remove its old fields, not merge them.
        if git --no-pager config get --file ${custom} --all credential.https://github.com.helper; then
          echo "GitHub's original helper survived replacement"
          exit 1
        else
          test "$?" -eq 1
        fi
        test "$(git --no-pager config get --file ${custom} credential.https://github.com.useHttpPath)" = true
        printf '%s\n' "" global-helper >expected
        git --no-pager config get --file ${custom} --all credential.helper >actual
        cmp expected actual
        printf '%s\n' "" first-helper second-helper >expected
        git --no-pager config get --file ${custom} --all credential.https://gist.github.com.helper >actual
        cmp expected actual
        printf '%s\n' "" example-helper >expected
        git --no-pager config get --file ${custom} --all credential.https://git.example.com.helper >actual
        cmp expected actual
        test "$(git --no-pager config get --file ${custom} credential.https://git.example.com.useHttpPath)" = true
        test "$(git --no-pager config get --file ${custom} user.name)" = "Joshua Peek"
        touch "$out"
      '';

    module-settings =
      let
        custom = wlibEvalPackage [
          ../modules/git-wrapper.nix
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
