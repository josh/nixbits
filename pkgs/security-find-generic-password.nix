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
    ${nixbits.xtrace}/bin/x -s -- ${security}/bin/security find-generic-password "$@"
  '';
in
stdenvNoCC.mkDerivation (_finalAttrs: {
  name = "security-find-generic-password";

  __structuredAttrs = true;

  nativeBuildInputs = [ makeWrapper ];

  makeWrapperArgs = [ ];

  securityAccount = "";
  securityLabel = "";
  securityService = "";
  securityPrintPassword = true;

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
    mainProgram = "security-find-generic-password";
    platforms = lib.platforms.darwin;
  };
})
