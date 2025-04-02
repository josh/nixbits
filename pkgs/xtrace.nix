{
  lib,
  stdenvNoCC,
  runCommand,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  __structuredAttrs = true;

  name = "xtrace";

  buildCommand = ''
    mkdir -p $out/bin $out/share/bash

    (
      echo "#!$SHELL"
      echo "source $out/share/bash/xtrace.bash"
      cat ${./x.bash}
    ) >$out/bin/x
    chmod +x $out/bin/x

    cat ${./xtrace.bash} >$out/share/bash/xtrace.bash
  '';

  passthru.tests =
    let
      xtrace = finalAttrs.finalPackage;
    in
    {
      lib-x-fmt = runCommand "test-xtrace-lib-x-fmt" { } ''
        source ${xtrace}/share/bash/xtrace.bash

        [ "$(x-fmt hello)" = "+ hello" ]
        [ "$(x-fmt hello world)" = "+ hello world" ]
        [ "$(x-fmt msg -m 'hello world')" = "+ msg -m 'hello world'" ]

        touch $out
      '';

      bin-x = runCommand "test-xtrace-bin-x" { nativeBuildInputs = [ xtrace ]; } ''
        x -- echo hello 1>out 2>err
        [ "$(cat err)" = "+ echo hello" ]
        [ "$(cat out)" = "hello" ]

        touch $out
      '';
    };

  meta = {
    description = "Explicit xtrace logging";
    mainProgram = "x";
    platforms = lib.platforms.all;
  };
})
