{
  lib,
  stdenvNoCC,
  writeShellScript,
  makeWrapper,
  gnugrep,
  nixbits,
  name ? (if shortcutSlug == "" then "shortcuts-run" else "shortcuts-run-${shortcutSlug}"),
  mainProgram ? name,
  shortcutSlug ? lib.strings.toLower (
    lib.strings.replaceStrings [ " " "\"" "'" ] [ "-" "" "" ] shortcutName
  ),
  shortcutName ? "",
  shortcutId ? "00000000-0000-0000-0000-000000000000",
}:
let
  inherit (nixbits.darwin) shortcuts;

  preinstallHook = writeShellScript "shortcuts-preinstall-hook" ''
    set -o errexit
    set -o nounset
    set -o pipefail
    export PATH=${
      lib.strings.makeBinPath [
        shortcuts
        gnugrep
      ]
    }

    if ! shortcuts list --show-identifiers | grep --quiet "(${shortcutId})"; then
      echo "error: Shortcut '${shortcutName} (${shortcutId})' not found" >&2
      exit 1
    fi
    if ! shortcuts list --show-identifiers | grep --quiet "${shortcutName} (${shortcutId})"; then
      echo "warn: Shortcut '${shortcutId}' expected to be named '${shortcutName}'" >&2
    fi
  '';
in
stdenvNoCC.mkDerivation (finalAttrs: {
  __structuredAttrs = true;

  inherit name;

  nativeBuildInputs = [ makeWrapper ];
  makeWrapperArgs = [
    "--add-flags"
    "run ${shortcutId}"
  ];

  buildCommand = ''
    mkdir -p $out/bin $out/share/nix/hooks/pre-install.d
    makeWrapper ${lib.getExe shortcuts} $out/bin/${mainProgram} "''${makeWrapperArgs[@]}"
    install -m 755 ${preinstallHook} $out/share/nix/hooks/pre-install.d/${finalAttrs.name}
  '';

  meta = {
    description = "Run '${shortcutName}' Shortcut";
    platforms = lib.platforms.darwin;
    inherit mainProgram;
  };
})
