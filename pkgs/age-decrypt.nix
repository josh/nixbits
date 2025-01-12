{
  stdenv,
  makeWrapper,
  runCommand,
  nixbits,
  age,
  age-input ? nixbits.empty-file,
}:
stdenv.mkDerivation (finalAttrs: {
  name = "age-decrypt";
  inherit (age) version;

  nativeBuildInputs = [ makeWrapper ];

  AGE_INPUT = age-input;

  buildCommand = ''
    if [ ! -f "$AGE_INPUT" ]; then
      echo "error: $AGE_INPUT not a file" >&2
      exit 1
    fi

    mkdir -p $out/bin
    makeWrapper ${age}/bin/age $out/bin/age-decrypt \
      --add-flags "--decrypt" \
      --append-flags "$AGE_INPUT"
  '';

  meta = {
    inherit (age.meta)
      homepage
      description
      license
      platforms
      ;
    mainProgram = "age-decrypt";
  };

  passthru.tests =
    let
      identity = builtins.toFile "key.txt" ''
        AGE-SECRET-KEY-1XT05JRC9UUPTZET3YHH5EYC8Z4QKMQN3NXP4E85KG47946U529QQFL43S2
      '';
      data = builtins.toFile "data.age" ''
        -----BEGIN AGE ENCRYPTED FILE-----
        YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBEL1hLRU1ZbE1hcEYybXp0
        SkFxOUVqVkpaOTA0YWthOGxTY0t2aDA0dldZCnJkTGdPTHR1U0FpaXJDTkxZc1dG
        d2xQWXMxYXZRQm9XUnZ5UndaY1FsYXMKLS0tIHRsNVVTUDhMemhEWFJZUEFXNzV5
        SkMwbmt0MU96a0s2UUV4N2UvSWNkazgKvEqwr1zxWWFHz7NiHfgLQXsJcg7O8SJN
        AQxIIbneSxQvVy5k
        -----END AGE ENCRYPTED FILE-----
      '';
      age-decrypt = finalAttrs.finalPackage.overrideAttrs { AGE_INPUT = "${data}"; };
    in
    {
      decrypt = runCommand "test-age-decrypt" { nativeBuildInputs = [ age-decrypt ]; } ''
        age-decrypt --identity ${identity} >data.txt
        if [ "$(cat data.txt)" = "foo" ]; then
          cp data.txt $out
        else
          echo "expected: foo"
          echo -n "actual:"
          cat data.txt
          exit 1
        fi
      '';
    };
})
