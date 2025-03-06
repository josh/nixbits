{
  lib,
  stdenvNoCC,
  makeWrapper,
  nixbits,
}:
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
    prependToVar makeWrapperArgs "--add-flags" "find-generic-password"

    if [ -n "$securityAccount" ]; then
      appendToVar makeWrapperArgs "--add-flags" "-a '$securityAccount'"
    fi
    if [ -n "$securityLabel" ]; then
      appendToVar makeWrapperArgs "--add-flags" "-l '$securityLabel'"
    fi
    if [ -n "$securityService" ]; then
      appendToVar makeWrapperArgs "--add-flags" "-s '$securityService'"
    fi
    if [ "$securityPrintPassword" = true ]; then
      appendToVar makeWrapperArgs "--add-flags" "-w"
    fi

    mkdir -p $out/bin
    makeWrapper ${nixbits.darwin.security}/bin/security $out/bin/$name "''${makeWrapperArgs[@]}"
  '';

  meta = {
    description = "Find a generic password item in macOS Keychain";
    platforms = lib.platforms.darwin;
    mainProgram = finalAttrs.name;
  };
})
