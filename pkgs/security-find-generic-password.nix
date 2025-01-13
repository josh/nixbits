{
  lib,
  stdenv,
  makeWrapper,
  nixbits,
  security-item-account ? null,
  security-item-label ? null,
  security-item-service ? null,
  security-print-password ? false,
}:
stdenv.mkDerivation (_finalAttrs: {
  name = "security-find-generic-password";

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ nixbits.security-impure-darwin ];

  SECURITY_ITEM_ACCOUNT = security-item-account;
  SECURITY_ITEM_LABEL = security-item-label;
  SECURITY_ITEM_SERVICE = security-item-service;
  SECURITY_PRINT_PASSWORD = security-print-password;

  buildCommand = ''
    args=(--add-flags "find-generic-password")
    if [ -n "$SECURITY_ITEM_ACCOUNT" ]; then
      args+=(--add-flags "-a $SECURITY_ITEM_ACCOUNT")
    fi
    if [ -n "$SECURITY_ITEM_LABEL" ]; then
      args+=(--add-flags "-l $SECURITY_ITEM_LABEL")
    fi
    if [ -n "$SECURITY_ITEM_SERVICE" ]; then
      args+=(--add-flags "-s $SECURITY_ITEM_SERVICE")
    fi
    if [ "$SECURITY_PRINT_PASSWORD" = true ]; then
      args+=(--add-flags "-w")
    fi

    mkdir -p $out/bin
    makeWrapper ${nixbits.security-impure-darwin}/bin/security $out/bin/security-find-generic-password "''${args[@]}"
  '';

  meta = {
    description = "Find a generic password item in macOS Keychain";
    platforms = lib.platforms.darwin;
    mainProgram = "security-find-generic-password";
  };
})
