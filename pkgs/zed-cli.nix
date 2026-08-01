{
  lib,
  stdenvNoCC,
  runtimeShell,
  jq,
}:
let
  app = "/Applications/Zed.app";
in
stdenvNoCC.mkDerivation {
  name = "zed-cli";

  __structuredAttrs = true;

  nativeBuildInputs = [ jq ];

  wrapper = ''
    #!${runtimeShell} -e
    exec "${app}/Contents/MacOS/cli" "$@"
  '';

  preInstallHook = ''
    #!${runtimeShell} -e
    if [ ! -d '${app}' ]; then
      echo "warn: Zed is not installed" >&2
      echo "  https://zed.dev/download" >&2
    fi
  '';

  tccpolicyPolicy = {
    "dev.zed.Zed" = {
      "SystemPolicyAllFiles" = true;
    };
  };

  buildCommand = ''
    mkdir -p $out/bin $out/share/nix/hooks/pre-install.d
    echo "$wrapper" >$out/bin/zed
    chmod +x $out/bin/zed

    echo "$preInstallHook" >$out/share/nix/hooks/pre-install.d/zed
    chmod +x $out/share/nix/hooks/pre-install.d/zed

    mkdir -p $out/share/tccpolicy.d
    jq --raw-output '.tccpolicyPolicy' <"$NIX_ATTRS_JSON_FILE" >$out/share/tccpolicy.d/zed.json
  '';

  meta = {
    description = "Zed Command Line Tools";
    homepage = "https://zed.dev";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    mainProgram = "zed";
    platforms = lib.platforms.darwin;
  };
}
