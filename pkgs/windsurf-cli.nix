{
  lib,
  stdenvNoCC,
  runtimeShell,
  runCommandLocal,
  jq,
}:
let
  app = "/Applications/Windsurf.app";
in
stdenvNoCC.mkDerivation (finalAttrs: {
  name = "windsurf-cli";

  __structuredAttrs = true;

  wrapper = ''
    #!${runtimeShell} -e
    exec "${app}/Contents/Resources/app/bin/windsurf" "$@"
  '';

  preInstallHook = ''
    #!${runtimeShell} -e
    if [ ! -d '${app}' ]; then
      echo "warn: Windsurf is not installed" >&2
      echo "  https://codeium.com/download" >&2
    fi
  '';

  tccpolicyPolicy = {
    "com.exafunction.windsurf" = {
      "SystemPolicyAllFiles" = true;
    };
  };

  nativeBuildInputs = [ jq ];

  buildCommand = ''
    mkdir -p $out/bin $out/share/nix/hooks/pre-install.d
    echo "$wrapper" >$out/bin/windsurf
    chmod +x $out/bin/windsurf

    echo "$preInstallHook" >$out/share/nix/hooks/pre-install.d/windsurf
    chmod +x $out/share/nix/hooks/pre-install.d/windsurf

    mkdir -p $out/share/tccpolicy.d
    cat "$NIX_ATTRS_JSON_FILE" | jq --raw-output '.tccpolicyPolicy' >$out/share/tccpolicy.d/windsurf.json
  '';

  passthru.tests =
    let
      windsurf = finalAttrs.finalPackage;
    in
    {
      version =
        runCommandLocal "test-windsurf-version"
          {
            __impureHostDeps = [ app ];
            nativeBuildInputs = [ windsurf ];
          }
          ''
            if [ -d '${app}' ]; then
              windsurf --version
            fi
            touch $out
          '';
    };

  meta = {
    description = "Windsurf Command Line Tools";
    homepage = "https://codeium.com/windsurf";
    platforms = lib.platforms.darwin;
    mainProgram = "windsurf";
  };
})
