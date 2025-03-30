{
  lib,
  stdenvNoCC,
  runCommand,
  makeWrapper,
  lndir,
  age,
  age-plugin-se ? nur.repos.josh.age-plugin-se,
  age-plugin-tpm,
  nur,
  seSupport ? true,
  tpmSupport ? true,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname =
    if seSupport && tpmSupport then
      "age-with-se-and-tpm"
    else if seSupport then
      "age-with-se"
    else if tpmSupport then
      "age-with-tpm"
    else
      "age";

  inherit (age) version;

  __structuredAttrs = true;

  nativeBuildInputs = [
    makeWrapper
    lndir
  ];

  paths =
    [ age ] ++ (lib.optional seSupport age-plugin-se) ++ (lib.optional tpmSupport age-plugin-tpm);

  buildCommand = ''
    mkdir -p $out
    for p in "''${paths[@]}"; do
      lndir -silent "$p" $out
    done

    rm $out/bin/age
    makeWrapper ${age}/bin/age $out/bin/age --prefix PATH : "$out/bin"
  '';

  passthru.tests =
    let
      age = finalAttrs.finalPackage;
    in
    {
      help = runCommand "test-help" { nativeBuildInputs = [ age ]; } ''
        age --help
        touch $out
      '';
    }
    // (lib.attrsets.optionalAttrs tpmSupport {
      tpm-encrypt = runCommand "test-tpm-encrypt" { nativeBuildInputs = [ age ]; } ''
        echo "Hello World" | age --encrypt \
          --recipient age1tpm1qg86fn5esp30u9h6jy6zvu9gcsvnac09vn8jzjxt8s3qtlcv5h2x287wm36 \
          --armor
        touch $out
      '';
    })
    // (lib.attrsets.optionalAttrs seSupport {
      se-encrypt = runCommand "test-se-encrypt" { nativeBuildInputs = [ age ]; } ''
        echo "Hello World" | age --encrypt \
          --recipient age1se1qgg72x2qfk9wg3wh0qg9u0v7l5dkq4jx69fv80p6wdus3ftg6flwg5dz2dp \
          --armor
        touch $out
      '';
    });

  meta = {
    inherit (age.meta)
      changelog
      description
      homepage
      license
      ;
    platforms = lib.platforms.all;
    mainProgram = "age";
  };
})
