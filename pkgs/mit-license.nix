{
  lib,
  stdenvNoCC,
  makeWrapper,
  runCommand,
  bash,
  coreutils,
  gnused,
}:
let
  script = ''
    #!${bash}/bin/bash
    # usage: mit-license >LICENSE
    set -o errexit
    year=$(${coreutils}/bin/date +%Y)
    ${gnused}/bin/sed "s/20XX/$year/" ${./MIT-LICENSE.txt}
  '';
in
stdenvNoCC.mkDerivation (finalAttrs: {
  name = "mit-license";
  nativeBuildInputs = [ makeWrapper ];

  inherit script;
  passAsFile = [ "script" ];

  buildCommand = ''
    mkdir -p $out/bin
    install -m 755 $scriptPath $out/bin/mit-license
    ln -s $out/bin/mit-license $out/bin/license
  '';

  meta = {
    mainProgram = "mit-license";
    description = "Print MIT license";
    platforms = lib.platforms.all;
  };

  passthru.tests =
    let
      mit-license = finalAttrs.finalPackage;
    in
    {
      run = runCommand "test-license-run" { nativeBuildInputs = [ mit-license ]; } ''
        mit-license
        touch $out
      '';
    };
})
