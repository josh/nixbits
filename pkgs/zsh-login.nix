{
  lib,
  stdenvNoCC,
  runCommand,
  wlibEvalPackage,
  zsh,
  zshModule ? { },
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  name = "zsh-login";

  __structuredAttrs = true;

  text = ''
    if [[ ! -o login ]]; then
      echo "Error: This script must be run as a login shell" >&2
      return 1 2>/dev/null || exit 1
    fi
  ''
  + (wlibEvalPackage [
    ../modules/wrappers/zsh.nix
    {
      loginProfile.enable = lib.mkDefault true;
    }
    zshModule
  ]).configuration.zprofile.content;

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
      if ! zsh --interactive ${finalAttrs.finalPackage}; then
        touch $out
      fi
    '';

    login = runCommand "zsh-login" { nativeBuildInputs = [ zsh ]; } ''
      export HOME=$(mktemp -d)
      zsh --login ${finalAttrs.finalPackage}
      touch $out
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
    description = "Login shell initialization for Zsh";
    longDescription = ''
      Source via ~/.zprofile
    '';
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
})
