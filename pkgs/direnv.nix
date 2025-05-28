{
  stdenvNoCC,
  makeWrapper,
  runCommand,
  direnv,
  lndir,
  jq,
  nixbits,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  name = "direnv";

  __structuredAttrs = true;

  buildInputs = [ makeWrapper ];

  # TODO: Also export $DIRENV_CONFIG in shell before `direnv hook $shell`

  buildCommand = ''
    mkdir -p $out
    ${lndir}/bin/lndir -silent ${direnv} $out

    wrapProgram $out/bin/direnv \
      --set DIRENV_CONFIG '${nixbits.direnv-xdg-config-home}/direnv'
  '';

  passthru.tests =
    let
      direnv = finalAttrs.finalPackage;
    in
    {
      direnv-status =
        runCommand "test-direnv-status"
          {
            nativeBuildInputs = [
              direnv
              jq
            ];
          }
          ''
            direnv status
            direnv status --json

            actual="$(direnv status --json | jq --raw-output '.config.ConfigDir')"
            expected="${nixbits.direnv-xdg-config-home}/direnv"
            if [ "$actual" != "$expected" ]; then
              echo "expected config dir to be $expected but was $actual"
              return 1
            fi

            touch $out
          '';
    };

  inherit (direnv) meta;
})
