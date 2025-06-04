{
  lib,
  stdenvNoCC,
  runCommand,
  bash,
  direnv,
  shellcheck-minimal,
  starship,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  name = "bash-interactive";

  __structuredAttrs = true;

  text = ''
    if [[ $- != *i* ]]; then
      echo "Error: This script must be run in an interactive shell"
      exit 1
    fi

    eval -- "$(${lib.getExe starship} init bash --print-full-init)"

    eval "$(${lib.getExe direnv} hook bash)"
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
      bash -i ${finalAttrs.finalPackage}
      touch $out
    '';

    login = runCommand "bash-login" { nativeBuildInputs = [ bash ]; } ''
      export HOME=$(mktemp -d)
      if ! bash -l ${finalAttrs.finalPackage}; then
        touch $out
      fi
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
    description = "Bash interactive shell initialization";
    longDescription = ''
      Source via ~/.bashrc and ~/.bash_profile
    '';
  };
})
