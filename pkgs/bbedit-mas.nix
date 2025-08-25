{
  lib,
  stdenvNoCC,
  jq,
}:
stdenvNoCC.mkDerivation (_finalAttrs: {
  name = "bbedit-mas";

  __structuredAttrs = true;

  nativeBuildInputs = [ jq ];

  appPath = "/Applications/BBEdit.app";

  masID = 404009241;

  tccpolicyPolicy = {
    "com.barebones.bbedit" = {
      "SystemPolicyAllFiles" = true;
    };
  };

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

    mkdir -p $out/share/tccpolicy.d
    cat "$NIX_ATTRS_JSON_FILE" | jq --raw-output '.tccpolicyPolicy' >$out/share/tccpolicy.d/bbedit.json
  '';

  meta = {
    description = "BBEdit Command Line Tools";
    homepage = "https://www.barebones.com/products/bbedit/";
    platforms = lib.platforms.darwin;
    mainProgram = "bbedit";
  };
})
