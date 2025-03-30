{
  lib,
  stdenvNoCC,
  runCommand,
  makeWrapper,
  lndir,
  age,
  age-plugin-se ? nur.repos.josh.age-plugin-se,
  age-plugin-tpm,
  age-plugin-yubikey,
  nur,
  seSupport ? true,
  tpmSupport ? true,
  yubikeySupport ? true,
}:
let
  features =
    (lib.optional seSupport "se")
    ++ (lib.optional tpmSupport "tpm")
    ++ (lib.optional yubikeySupport "yubikey");
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = if features == [ ] then "age" else "age-with-${builtins.concatStringsSep "-" features}";

  inherit (age) version;

  __structuredAttrs = true;

  nativeBuildInputs = [
    makeWrapper
    lndir
  ];

  paths =
    [ age ]
    ++ (lib.optional seSupport age-plugin-se)
    ++ (lib.optional tpmSupport age-plugin-tpm)
    ++ (lib.optional yubikeySupport age-plugin-yubikey);

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
    })
    // (lib.attrsets.optionalAttrs yubikeySupport {
      yubikey-encrypt = runCommand "test-yubikey-encrypt" { nativeBuildInputs = [ age ]; } ''
        echo "Hello World" | age --encrypt \
          --recipient age1yubikey1q2w7u3vpya839jxxuq8g0sedh3d740d4xvn639sqhr95ejj8vu3hyfumptt \
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
