{
  lib,
  stdenvNoCC,
  runCommand,
  wlibEvalPackage,
  zsh,
  zoxide,
  zshModule ? { },
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  name = "zsh-interactive";
  __structuredAttrs = true;

  text = ''
    if [[ ! -o interactive ]]; then
      echo "Error: This script must be run in an interactive shell"
      return 1 2>/dev/null || exit 1
    fi
  ''
  + (wlibEvalPackage [
    ../modules/wrappers/zsh.nix
    {
      interactiveProfile.enable = lib.mkDefault true;
      zoxide.package = lib.mkDefault zoxide;
    }
    zshModule
  ]).configuration.zshrc.content;

  buildCommand = ''
    echo -n "$text" >"$out"

    ${zsh}/bin/zsh --no-exec "$out"
  '';

  passthru.tests = {
    script = runCommand "zsh-script" { nativeBuildInputs = [ zsh ]; } ''
      export HOME=$(mktemp -d)
      if ! zsh ${finalAttrs.finalPackage}; then
        touch $out
      fi
    '';

    interactive = runCommand "zsh-interactive" { nativeBuildInputs = [ zsh ]; } ''
      export HOME=$(mktemp -d)
      zsh --interactive ${finalAttrs.finalPackage}
      touch $out
    '';

    login = runCommand "zsh-login" { nativeBuildInputs = [ zsh ]; } ''
      export HOME=$(mktemp -d)
      if ! zsh --login ${finalAttrs.finalPackage}; then
        touch $out
      fi
    '';

    interactive-login-interactive =
      runCommand "zsh-interactive-login-interactive" { nativeBuildInputs = [ zsh ]; }
        ''
          export HOME=$(mktemp -d)
          zsh --login --interactive ${finalAttrs.finalPackage}
          touch $out
        '';
  };

  meta = {
    description = "Interactive shell initialization for Zsh";
    longDescription = ''
      Source via ~/.zshrc and ~/.zprofile
    '';
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
})
