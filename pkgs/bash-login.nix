{
  stdenvNoCC,
  runCommand,
  bash,
  shellcheck-minimal,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  name = "bash-login";

  __structuredAttrs = true;

  text = ''
    if ! shopt -q login_shell; then
      echo "Error: This script must be run as a login shell" >&2
      exit 1
    fi
  '';

  nativeBuildInputs = [
    shellcheck-minimal
  ];

  buildCommand = ''
    echo -n "$text" >"$out"

    runHook preCheck
    ${bash}/bin/bash -n "$out"
    shellcheck --shell=bash "$out"
    runHook postCheck
  '';

  passthru.tests = {
    script = runCommand "bash-script" { nativeBuildInputs = [ bash ]; } ''
      export HOME=$(mktemp -d)
      if ! bash ${finalAttrs.finalPackage}; then
        touch $out
      fi
    '';

    interactive = runCommand "bash-interactive" { nativeBuildInputs = [ bash ]; } ''
      export HOME=$(mktemp -d)
      if ! bash -i ${finalAttrs.finalPackage}; then
        touch $out
      fi
    '';

    login = runCommand "bash-login" { nativeBuildInputs = [ bash ]; } ''
      export HOME=$(mktemp -d)
      bash -l ${finalAttrs.finalPackage}
      touch $out
    '';

    interactive-login-interactive =
      runCommand "bash-interactive-login-interactive" { nativeBuildInputs = [ bash ]; }
        ''
          export HOME=$(mktemp -d)
          bash -l -i ${finalAttrs.finalPackage}
          touch $out
        '';
  };

  meta = {
    description = "Bash login shell initialization";
    longDescription = ''
      Source via ~/.bash_profile
    '';
  };
})
