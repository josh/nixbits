{
  lib,
  stdenvNoCC,
  writeShellScript,
  makeWrapper,
  nixbits,
}:
let
  inherit (nixbits.darwin) security;
  preinstallHook = writeShellScript "security-find-generic-password-preinstall-hook" ''
    if ! ${security}/bin/security find-generic-password "$@" >/dev/null 2>&1; then
      echo "warn: keychain missing generic password for $@" >&2
    fi
  '';
in
stdenvNoCC.mkDerivation (finalAttrs: {
  __structuredAttrs = true;

  name = "security-find-generic-password";

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ nixbits.darwin.security ];

  securityAccount = "";
  securityLabel = "";
  securityService = "";
  securityPrintPassword = true;

  makeWrapperArgs = [ ];

  buildCommand = ''
    if [ -n "$securityAccount" ]; then
      appendToVar makeWrapperArgs "--add-flags" "-a '$securityAccount'"
    fi
    if [ -n "$securityLabel" ]; then
      appendToVar makeWrapperArgs "--add-flags" "-l '$securityLabel'"
    fi
    if [ -n "$securityService" ]; then
      appendToVar makeWrapperArgs "--add-flags" "-s '$securityService'"
    fi

    mkdir -p $out/share/nix/hooks/pre-install.d
    makeWrapper ${preinstallHook} $out/share/nix/hooks/pre-install.d/$name \
      "''${makeWrapperArgs[@]}"

    if [ -n "$securityPrintPassword" ]; then
      appendToVar makeWrapperArgs "--add-flags" "-w"
    fi

    mkdir -p $out/bin
    makeWrapper ${security}/bin/security $out/bin/$name \
      --add-flags find-generic-password \
      "''${makeWrapperArgs[@]}"
  '';

  meta = {
    description = "Find a generic password item in macOS Keychain";
    platforms = lib.platforms.darwin;
    mainProgram = finalAttrs.name;
  };
})
