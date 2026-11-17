{
  lib,
  wlibEvalPackage,
  runCommand,
  writeShellScriptBin,
  jujutsu,
  nixbits,
  git-package ? nixbits.git,
}:
let
  wrapper = wlibEvalPackage [
    ../modules/jujutsu-wrapper.nix
    { settings.git.executable-path = lib.mkForce (lib.getExe git-package); }
  ];
  config = runCommand "jj-config.toml" { } ''
    cp ${wrapper.configuration.constructFiles.generatedConfig} "$out"
  '';
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

  passthru.tests.module-settings =
    let
      customGit = writeShellScriptBin "git" "exit 1";
      custom = wlibEvalPackage [
        ../modules/jujutsu-wrapper.nix
        {
          settings.user.name = lib.mkForce "Module User";
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

  passthru.tests.git-package-override =
    let
      customGit = writeShellScriptBin "git" "exit 1";
      customConfig = nixbits.jujutsu-config.override { git-package = customGit; };
    in
    runCommand "test-jj-config-git-package-override" { nativeBuildInputs = [ jujutsu ]; } ''
      export HOME="$PWD/home"
      mkdir -p "$HOME"
      test "$(JJ_CONFIG=${nixbits.jujutsu-config} jj config get git.executable-path)" = "${lib.getExe nixbits.git}"
      test "$(JJ_CONFIG=${customConfig} jj config get git.executable-path)" = "${lib.getExe customGit}"
      touch $out
    '';

  meta = {
    description = "Configuration for the Jujutsu version control system";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
