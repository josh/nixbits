{
  lib,
  stdenvNoCC,
  runtimeShell,
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

  ageWrapperScript = ''
    #!${runtimeShell}
    set -o errexit
    PATH="${builtins.placeholder "out"}/bin:$PATH"
    export PATH

    args=()
    while [ $# -gt 0 ]; do
      case "$1" in
      --identity-command)
        exec 3< <($2)
        args+=("--identity" "/dev/fd/3")
        shift 2
        ;;
      *)
        args+=("$1")
        shift
        ;;
      esac
    done

    exec ${age}/bin/age "''${args[@]}"
  '';

  buildCommand = ''
    mkdir -p $out
    for p in "''${paths[@]}"; do
      lndir -silent "$p" $out
    done

    rm $out/bin/age
    echo "$ageWrapperScript" >$out/bin/age
    chmod +x $out/bin/age
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

      identity-command = runCommand "test-identity-command" { nativeBuildInputs = [ age ]; } ''
        echo "Hello World" >data-a.txt
        age-keygen >key.txt
        age-keygen -y key.txt >recipient.txt
        age --encrypt --recipients-file recipient.txt data-a.txt >data.age
        age --decrypt --identity-command 'cat key.txt' data.age >data-b.txt
        if [ "$(cat data-a.txt)" != "$(cat data-b.txt)" ]; then
          echo "expected: $(cat data-a.txt)"
          echo -n "actual:"
          cat data-b.txt
          exit 1
        fi
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
