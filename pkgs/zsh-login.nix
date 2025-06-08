{
  lib,
  stdenvNoCC,
  runCommand,
  zsh,
  nixbits,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  name = "zsh-login";

  __structuredAttrs = true;

  text =
    ''
      if [[ ! -o login ]]; then
        echo "Error: This script must be run as a login shell" >&2
        exit 1
      fi

      if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
        . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
      fi
    ''
    + (lib.strings.optionalString stdenvNoCC.isDarwin ''
      if [ -n "$ZED_TERM" ]; then
      	export EDITOR="${nixbits.zed-cli}/bin/zed --wait"
      fi
    '');

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
    description = "Zsh login shell initialization";
    longDescription = ''
      Source via ~/.zprofile
    '';
  };
})
