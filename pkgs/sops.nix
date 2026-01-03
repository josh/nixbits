{
  pkgs,
  lib,
  stdenvNoCC,
  runCommand,
  makeWrapper,
  lndir,
  sops,
  nur,
  age,
  age-plugin-se,
  age-plugin-tpm,
  age-plugin-yubikey,
  seSupport ? true,
  tpmSupport ? true,
  yubikeySupport ? true,
}:
let
  age-plugin-se' =
    if age-plugin-se == pkgs.age-plugin-se then nur.repos.josh.age-plugin-se else age-plugin-se;
  age-plugin-tpm' =
    if age-plugin-tpm == pkgs.age-plugin-tpm then nur.repos.josh.age-plugin-tpm else age-plugin-tpm;
  age-plugin-yubikey' = age-plugin-yubikey;

  features =
    (lib.optional seSupport "se")
    ++ (lib.optional tpmSupport "tpm")
    ++ (lib.optional yubikeySupport "yubikey");
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = if features == [ ] then "sops" else "sops-with-${builtins.concatStringsSep "-" features}";

  inherit (sops) version;

  __structuredAttrs = true;

  nativeBuildInputs = [
    makeWrapper
    lndir
  ];

  paths = [
    sops
    age
  ]
  ++ (lib.optional seSupport age-plugin-se')
  ++ (lib.optional tpmSupport age-plugin-tpm')
  ++ (lib.optional yubikeySupport age-plugin-yubikey');

  buildCommand = ''
    mkdir -p $out
    for p in "''${paths[@]}"; do
      lndir -silent "$p" $out
    done

    rm $out/bin/sops
    makeWrapper ${sops}/bin/sops $out/bin/sops --prefix PATH : "$out/bin"
    chmod +x $out/bin/sops
  '';

  passthru.tests =
    let
      sops = finalAttrs.finalPackage;
      dataFile = builtins.toFile "example.json" ''{"foo": "bar"}'';
    in
    {
      help = runCommand "test-help" { nativeBuildInputs = [ sops ]; } ''
        sops --help
        touch $out
      '';
    }
    // (lib.attrsets.optionalAttrs (lib.strings.versionAtLeast age.version "1.3.0") {
      tag-encrypt = runCommand "test-tag-encrypt" { nativeBuildInputs = [ sops ]; } ''
        sops encrypt --age age1tag1qwe0kafsjrar4txm6heqnhpfuggzr0gvznz7fvygxrlq90u5mq2pysxtw6h ${dataFile}
        touch $out
      '';
    })
    // (lib.attrsets.optionalAttrs tpmSupport {
      tpm-encrypt = runCommand "test-tpm-encrypt" { nativeBuildInputs = [ sops ]; } ''
        sops encrypt --age age1tpm1qg86fn5esp30u9h6jy6zvu9gcsvnac09vn8jzjxt8s3qtlcv5h2x287wm36 ${dataFile}
        touch $out
      '';
    })
    // (lib.attrsets.optionalAttrs seSupport {
      se-encrypt = runCommand "test-se-encrypt" { nativeBuildInputs = [ sops ]; } ''
        sops encrypt --age age1se1qgg72x2qfk9wg3wh0qg9u0v7l5dkq4jx69fv80p6wdus3ftg6flwg5dz2dp ${dataFile}
        touch $out
      '';
    })
    // (lib.attrsets.optionalAttrs yubikeySupport {
      yubikey-encrypt = runCommand "test-yubikey-encrypt" { nativeBuildInputs = [ sops ]; } ''
        sops encrypt --age age1yubikey1q2w7u3vpya839jxxuq8g0sedh3d740d4xvn639sqhr95ejj8vu3hyfumptt ${dataFile}
        touch $out
      '';
    });

  meta = {
    inherit (sops.meta)
      changelog
      description
      homepage
      license
      ;
    platforms = lib.platforms.all;
    mainProgram = "sops";
  };
})
