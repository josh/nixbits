{
  lib,
  stdenvNoCC,
  makeWrapper,
  nixbits,
  security-item-account ? null,
  security-item-label ? null,
  security-item-service ? null,
  security-print-password ? false,
}:
stdenvNoCC.mkDerivation (_finalAttrs: {
  __structuredAttrs = true;

  name = "security-find-generic-password";

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ nixbits.darwin.security ];

  makeWrapperArgs =
    (lib.lists.optionals (security-item-account != null) [
      "--add-flags"
      "-a ${security-item-account}"
    ])
    ++ (lib.lists.optionals (security-item-label != null) [
      "--add-flags"
      "-l ${security-item-label}"
    ])
    ++ (lib.lists.optionals (security-item-service != null) [
      "--add-flags"
      "-s ${security-item-service}"
    ])
    ++ (lib.lists.optionals security-print-password [
      "--add-flags"
      "-w"
    ]);

  buildCommand = ''
    mkdir -p $out/bin
    prependToVar makeWrapperArgs "--add-flags" "find-generic-password"
    makeWrapper ${nixbits.darwin.security}/bin/security $out/bin/security-find-generic-password "''${makeWrapperArgs[@]}"
  '';

  meta = {
    description = "Find a generic password item in macOS Keychain";
    platforms = lib.platforms.darwin;
    mainProgram = "security-find-generic-password";
  };
})
