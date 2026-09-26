{
  lib,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation {
  name = "bbedit-mas";

  __structuredAttrs = true;

  appPath = "/Applications/BBEdit.app";

  masID = 404009241;

  preinstallHookScript = ''
    if [ ! -d "/Applications/BBEdit.app" ]; then
      echo "warn: BBEdit is not installed" >&2
      echo "  https://www.barebones.com/products/bbedit/" >&2
    fi
  '';

  buildCommand = ''
    mkShellScript() {
      echo "#!$shell" >"$2"
      echo -n "$1" >>"$2"
      chmod +x "$2"
    }

    mkdir -p $out/bin
    mkShellScript "exec \"$appPath/Contents/Helpers/bbedit_tool\" \"\$@\"" "$out/bin/bbedit"
    mkShellScript "exec \"$appPath/Contents/Helpers/bbdiff\" \"\$@\"" "$out/bin/bbdiff"
    mkShellScript "exec \"$appPath/Contents/Helpers/bbfind\" \"\$@\"" "$out/bin/bbfind"
    mkShellScript "exec \"$appPath/Contents/Helpers/bbresults\" \"\$@\"" "$out/bin/bbresults"

    mkdir -p $out/share/nix/hooks/pre-install.d
    mkShellScript "$preinstallHookScript" "$out/share/nix/hooks/pre-install.d/bbedit"

    mkdir -p $out/share/mas
    echo "BBEdit" >$out/share/mas/$masID
  '';

  meta = {
    description = "Command line tools for the BBEdit text editor";
    homepage = "https://www.barebones.com/products/bbedit/";
    license = lib.licenses.unfree;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    mainProgram = "bbedit";
    platforms = lib.platforms.darwin;
  };
}
