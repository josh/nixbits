{
  lib,
  stdenvNoCC,
  runtimeShell,
  runCommand,
  nixbits,
}:
let
  rex = "$HOME/Library/Application Support/com.superlogical.rex/RexServer/Versions/Current/Rex Server.app/Contents/MacOS/rex";
in
stdenvNoCC.mkDerivation {
  name = "rex-cli";

  __structuredAttrs = true;

  wrapper = ''
    #!${runtimeShell}
    rex="${rex}"
    if [ ! -x "$rex" ]; then
      echo "error: Rex is not installed" >&2
      exit 127
    fi
    exec "$rex" "$@"
  '';

  preInstallHook = ''
    #!${runtimeShell} -e
    if [ ! -x "${rex}" ]; then
      echo "warn: Rex is not installed" >&2
    fi
  '';

  buildCommand = ''
    mkdir -p $out/bin $out/share/nix/hooks/pre-install.d
    echo "$wrapper" >$out/bin/rex
    chmod +x $out/bin/rex

    echo "$preInstallHook" >$out/share/nix/hooks/pre-install.d/rex
    chmod +x $out/share/nix/hooks/pre-install.d/rex
  '';

  passthru.tests = {
    without-rex = runCommand "test-rex-cli-without-rex" { } ''
      export HOME="$PWD/home"
      mkdir "$HOME"
      status=0
      output="$(${lib.getExe nixbits.rex-cli} version 2>&1)" || status=$?
      if [ "$status" -ne 127 ] || [ "$output" != "error: Rex is not installed" ]; then
        echo "expected exit 127 with an error but was $status: '$output'"
        return 1
      fi
      touch $out
    '';
  };

  meta = {
    description = "Command line tools for the Rex terminal";
    license = lib.licenses.unfree;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    mainProgram = "rex";
    platforms = lib.platforms.darwin;
  };
}
