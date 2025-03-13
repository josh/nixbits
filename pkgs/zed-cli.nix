{
  lib,
  stdenvNoCC,
  runtimeShell,
  runCommandLocal,
}:
let
  app = "/Applications/Zed.app";
in
stdenvNoCC.mkDerivation (finalAttrs: {
  name = "zed-cli";

  __structuredAttrs = true;

  wrapper = ''
    #!${runtimeShell} -e
    exec "${app}/Contents/MacOS/cli" "$@"
  '';
  preInstallHook = ''
    #!${runtimeShell} -e
    if [ ! -d '${app}' ]; then
      echo "WARN: Zed not installed" >&2
      echo "  https://zed.dev/download" >&2
    fi
  '';

  buildCommand = ''
    mkdir -p $out/bin $out/share/nix/hooks/pre-install.d
    echo "$wrapper" >$out/bin/zed
    chmod +x $out/bin/zed
    echo "$preInstallHook" >$out/share/nix/hooks/pre-install.d/zed
    chmod +x $out/share/nix/hooks/pre-install.d/zed
  '';

  passthru.tests =
    let
      zed = finalAttrs.finalPackage;
    in
    {
      version =
        runCommandLocal "test-zed-version"
          {
            __impureHostDeps = [ app ];
            nativeBuildInputs = [ zed ];
          }
          ''
            if [ -d '${app}' ]; then
              zed --version
            fi
            touch $out
          '';
    };

  meta = {
    description = "Zed Command Line Tools";
    homepage = "https://zed.dev";
    platforms = lib.platforms.darwin;
    mainProgram = "zed";
  };
})
