{
  lib,
  stdenvNoCC,
  runtimeShell,
  jq,
}:
let
  app = "/Applications/Zed.app";
in
stdenvNoCC.mkDerivation (_finalAttrs: {
  name = "zed-cli";

  __structuredAttrs = true;

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

  nativeBuildInputs = [ jq ];

  buildCommand = ''
    mkdir -p $out/bin $out/share/nix/hooks/pre-install.d
    echo "$wrapper" >$out/bin/zed
    chmod +x $out/bin/zed

    echo "$preInstallHook" >$out/share/nix/hooks/pre-install.d/zed
    chmod +x $out/share/nix/hooks/pre-install.d/zed

    mkdir -p $out/share/tccpolicy.d
    cat "$NIX_ATTRS_JSON_FILE" | jq --raw-output '.tccpolicyPolicy' >$out/share/tccpolicy.d/zed.json
  '';

  meta = {
    description = "Zed Command Line Tools";
    homepage = "https://zed.dev";
    platforms = lib.platforms.darwin;
    mainProgram = "zed";
  };
})
