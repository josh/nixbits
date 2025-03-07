{
  lib,
  stdenvNoCC,
  makeWrapper,
  nixbits,
}:
let
  inherit (nixbits.darwin) shortcuts;
in
stdenvNoCC.mkDerivation (finalAttrs: {
  __structuredAttrs = true;

  pname = "shortcuts-run";
  name =
    if finalAttrs.shortcutSlug == "" then
      "shortcuts-run"
    else
      "shortcuts-run-${finalAttrs.shortcutSlug}";

  shortcutId = "00000000-0000-0000-0000-000000000000";
  shortcutName = "";
  shortcutSlug = lib.strings.toLower (
    lib.strings.replaceStrings [ " " "\"" "'" ] [ "-" "" "" ] finalAttrs.shortcutName
  );

  nativeBuildInputs = [ makeWrapper ];
  makeWrapperArgs = [ ];
  preInstallHookMakeWrapperArgs = [ ];

  buildCommand = ''
    appendToVar makeWrapperArgs "--add-flags" "run $shortcutId"
    appendToVar preInstallHookMakeWrapperArgs "--add-flags" "--id $shortcutId"

    if [ -n "$shortcutName" ]; then
      appendToVar preInstallHookMakeWrapperArgs "--add-flags" "--name \"$shortcutName\""
    fi

    mkdir -p $out/bin $out/share/nix/hooks/pre-install.d
    makeWrapper ${lib.getExe shortcuts} $out/bin/$name "''${makeWrapperArgs[@]}"
    makeWrapper ${lib.getExe nixbits.shortcuts-check} $out/share/nix/hooks/pre-install.d/$name "''${preInstallHookMakeWrapperArgs[@]}"
  '';

  meta = {
    description = "Run '${finalAttrs.shortcutName}' Shortcut";
    platforms = lib.platforms.darwin;
    mainProgram = finalAttrs.name;
  };
})
