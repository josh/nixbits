{
  lib,
  stdenvNoCC,
  runCommand,
  direnv,
  starship,
  zsh,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  name = "zsh-interactive";

  __structuredAttrs = true;

  text = ''
    if [[ ! -o interactive ]]; then
      echo "Error: This script must be run in an interactive shell"
      exit 1
    fi

    eval "$(${lib.getExe starship} init zsh)"

    eval "$(${lib.getExe direnv} hook zsh)"
  '';

  buildCommand = ''
    echo -n "$text" >"$out"

    runHook preCheck
    ${zsh}/bin/zsh --no-exec "$out"
    runHook postCheck
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
    description = "Zsh interactive shell initialization";
    longDescription = ''
      Source via ~/.zshrc and ~/.zprofile
    '';
  };
})
