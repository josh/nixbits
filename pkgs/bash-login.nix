{
  lib,
  stdenvNoCC,
  runCommand,
  bash,
  shellcheck-minimal,
  nixbits,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  name = "bash-login";

  __structuredAttrs = true;

  text = ''
    if ! shopt -q login_shell; then
      echo "Error: This script must be run as a login shell" >&2
      exit 1
    fi

    if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
      # shellcheck disable=SC1091
      . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
    fi
  ''
  + (lib.strings.optionalString stdenvNoCC.isDarwin ''
    if [ -n "$ZED_TERM" ]; then
    	export EDITOR="${nixbits.zed-cli}/bin/zed --wait"
    fi
  '');

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
