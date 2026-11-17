{
  lib,
  wlibEvalPackage,
  runCommand,
  writeShellScriptBin,
  jujutsu,
  nixbits,
}:
let
  wrapper = wlibEvalPackage ../modules/jujutsu-wrapper.nix;
  config = wrapper.configuration.configFile.path;
in
config.overrideAttrs {
  passthru.tests.defaults =
    runCommand "test-jj-config-defaults" { nativeBuildInputs = [ jujutsu ]; }
      ''
        export HOME="$TMPDIR/home" JJ_CONFIG=${config}
        mkdir -p "$HOME"
        cmp ${config} ${wrapper.configuration.constructFiles.generatedConfig}
        test "$(jj config get user.name)" = "Joshua Peek"
        test "$(jj config get user.email)" = josh@users.noreply.github.com
        test "$(jj config get git.executable-path)" = "${lib.getExe nixbits.git}"
        test "$(jj config get ui.paginate)" = never
        test "$(jj config get ui.diff-editor)" = :builtin
        test "$(jj config get remotes.origin.auto-track-bookmarks)" = 'glob:push-*'
        jj git init repo
        cd repo
        test "$(jj log -r @ --no-graph -T 'author.name()')" = "Joshua Peek"
        test "$(jj log -r @ --no-graph -T 'author.email()')" = josh@users.noreply.github.com
        touch "$out"
      '';

  passthru.tests.standalone =
    let
      custom = wlibEvalPackage [
        ../modules/jujutsu-wrapper.nix
        {
          # Reading the generated config must not build the wrapper or its package.
          package = runCommand "unbuildable-jj" { meta.mainProgram = "jj"; } "exit 1";
          settings.user.name = "Standalone User";
          settings.user.email = "standalone@example.com";
        }
      ];
    in
    runCommand "test-jj-config-standalone" { nativeBuildInputs = [ jujutsu ]; } ''
      export HOME="$TMPDIR/home" JJ_CONFIG=${custom.configuration.configFile.path}
      mkdir -p "$HOME"
      test "$(jj config get user.name)" = "Standalone User"
      test "$(jj config get user.email)" = standalone@example.com
      test "$(jj config get git.executable-path)" = "${lib.getExe nixbits.git}"
      touch "$out"
    '';

  passthru.tests.module-settings =
    let
      customGit = writeShellScriptBin "git" "exit 1";
      custom = wlibEvalPackage [
        ../modules/jujutsu-wrapper.nix
        {
          settings.user.name = "Module User";
          settings.git.executable-path = lib.mkForce (lib.getExe customGit);
        }
      ];
    in
    runCommand "test-jj-wrapper-module-settings" { } ''
      export HOME="$TMPDIR/home" JJ_CONFIG=/ignored/jj-config
      mkdir -p "$HOME"
      test "$(${lib.getExe custom} config get user.name)" = "Module User"
      test "$(${lib.getExe custom} config get user.email)" = josh@users.noreply.github.com
      test "$(${lib.getExe custom} config get git.executable-path)" = "${lib.getExe customGit}"
      touch "$out"
    '';

  passthru.tests.identity-propagation =
    let
      customGit = wlibEvalPackage [
        ../modules/git-wrapper.nix
        {
          settings.user = {
            name = lib.mkForce "Shared Git User";
            email = lib.mkForce "shared@example.com";
            signingKey = "git-only-key";
          };
        }
      ];
      shared = wlibEvalPackage [
        ../modules/jujutsu-wrapper.nix
        { gitWrapper = customGit; }
      ];
      overridden = wlibEvalPackage [
        ../modules/jujutsu-wrapper.nix
        {
          gitWrapper = customGit;
          settings.user = {
            name = "Explicit JJ User";
            email = "jj@example.com";
          };
        }
      ];
    in
    runCommand "test-jj-wrapper-identity-propagation" { } ''
      export HOME="$TMPDIR/home" JJ_CONFIG=/ignored/jj-config
      mkdir -p "$HOME"
      test "$(${lib.getExe shared} config get user.name)" = "Shared Git User"
      test "$(${lib.getExe shared} config get user.email)" = shared@example.com
      test "$(${lib.getExe shared} config get git.executable-path)" = "${lib.getExe customGit}"
      test "$(${lib.getExe overridden} config get user.name)" = "Explicit JJ User"
      test "$(${lib.getExe overridden} config get user.email)" = jj@example.com
      test "$(${lib.getExe overridden} config get git.executable-path)" = "${lib.getExe customGit}"
      ${lib.getExe shared} config list --include-defaults >settings
      if grep -q 'user.signingKey' settings; then
        echo "Git-only user settings leaked into JJ"
        exit 1
      fi
      ${lib.getExe shared} git init shared-repo
      cd shared-repo
      test "$(${lib.getExe shared} log -r @ --no-graph -T 'author.name()')" = "Shared Git User"
      test "$(${lib.getExe shared} log -r @ --no-graph -T 'author.email()')" = shared@example.com
      cd ..
      ${lib.getExe overridden} git init overridden-repo
      cd overridden-repo
      test "$(${lib.getExe overridden} log -r @ --no-graph -T 'author.name()')" = "Explicit JJ User"
      test "$(${lib.getExe overridden} log -r @ --no-graph -T 'author.email()')" = jj@example.com
      touch "$out"
    '';

  meta = {
    description = "Configuration for the Jujutsu version control system";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
