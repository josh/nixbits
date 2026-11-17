{
  wlibEvalPackage,
  writeText,
  runCommand,
  nixbits,
  git-config ? nixbits.git-config,
}:
wlibEvalPackage [
  ../modules/git-wrapper.nix
  {
    configFile.path = git-config;
    passthru.tests = {
      config-override =
        let
          customConfig = writeText "custom-git-config" ''
            [user]
              name = Custom Git User
              email = custom@example.com
            [credential "https://git.example.com"]
              helper =
              helper = custom-helper
          '';
          customGit = nixbits.git.override { git-config = customConfig; };
          customModule = wlibEvalPackage [
            ../modules/git-wrapper.nix
            { configFile.path = customConfig; }
          ];
        in
        runCommand "test-git-config-override" { nativeBuildInputs = [ customGit ]; } ''
          export HOME="$TMPDIR/home"
          mkdir -p "$HOME"
          export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/ignored/git-config
          for gitBin in ${customGit}/bin/git ${customModule}/bin/git; do
            test "$("$gitBin" config get user.name)" = "Custom Git User"
            test "$("$gitBin" config get user.email)" = custom@example.com
            test "$("$gitBin" config get --url=https://git.example.com credential.helper)" = custom-helper
            test "$("$gitBin" config get --show-origin user.name)" = "$(printf 'file:%s\t%s' ${customConfig} 'Custom Git User')"
          done
          touch "$out"
        '';

    };
  }
]
