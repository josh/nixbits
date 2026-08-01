{
  lib,
  stdenvNoCC,
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

  __structuredAttrs = true;

  inherit script;

  buildCommand = ''
    mkdir -p $out/bin
    printf '%s' "$script" >$out/bin/mit-license
    chmod 755 $out/bin/mit-license
    ln -s $out/bin/mit-license $out/bin/license
  '';

  passthru.tests =
    let
      mit-license = finalAttrs.finalPackage;
    in
    {
      run = runCommand "test-license-run" { nativeBuildInputs = [ mit-license ]; } ''
        mit-license >license.txt
        grep --quiet --extended-regexp 'Copyright \(c\) 20[0-9]{2} Joshua Peek' license.txt
        if grep --quiet '20XX' license.txt; then
          echo "year placeholder was not substituted"
          exit 1
        fi
        touch $out
      '';

      alias = runCommand "test-license-alias" { nativeBuildInputs = [ mit-license ]; } ''
        license | cmp --quiet - <(mit-license)
        touch $out
      '';
    };

  meta = {
    description = "Print MIT license";
    license = lib.licenses.mit;
    mainProgram = "mit-license";
    platforms = lib.platforms.all;
  };
})
