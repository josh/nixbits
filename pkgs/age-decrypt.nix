{
  stdenvNoCC,
  writeShellScript,
  makeWrapper,
  runCommand,
  nixbits,
}:
let
  age = nixbits.age.override {
    seSupport = true;
    tpmSupport = true;
  };
  preinstallHook = writeShellScript "age-decrypt-preinstall-hook" ''
    ${nixbits.x-quiet}/bin/x-quiet -- "$1"
  '';
in
stdenvNoCC.mkDerivation (finalAttrs: {
  __structuredAttrs = true;

  pname = "age-decrypt";
  inherit (age) version;

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ age ];

  makeWrapperArgs = [ ];

  ageIdentity = "";
  ageInput = "";
  preinstallCheck = if finalAttrs.ageIdentity != "" && finalAttrs.ageInput != "" then true else false;

  buildCommand = ''
    if [ -n "$ageIdentity" ]; then
      if [[ "$ageIdentity" =~ ^$NIX_STORE/ ]]; then
        echo "error: identity cannot be a store path" >&2
        exit 1
      fi
      appendToVar makeWrapperArgs "--add-flags" "--identity $ageIdentity"
    fi

    if [ -n "$ageInput" ]; then
      if [[ "$ageInput" =~ ^$NIX_STORE/ ]] && [ ! -f "$ageInput" ]; then
        echo "error: store path '$ageInput' must be a file" >&2
        exit 1
      fi
      appendToVar makeWrapperArgs "--append-flags" "$ageInput"
    fi

    mkdir -p $out/bin
    prependToVar makeWrapperArgs "--add-flags" "--decrypt"
    makeWrapper ${age}/bin/age $out/bin/$pname "''${makeWrapperArgs[@]}"

    if [ -n "$preinstallCheck" ]; then
      mkdir -p $out/share/nix/hooks/pre-install.d
      makeWrapper ${preinstallHook} \
        $out/share/nix/hooks/pre-install.d/$pname \
        --append-flags "$out/bin/$pname"
    fi
  '';

  meta = {
    inherit (age.meta)
      homepage
      description
      license
      platforms
      ;
    mainProgram = finalAttrs.pname;
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
      age-decrypt = finalAttrs.finalPackage.overrideAttrs {
        pname = "age-decrypt-data";
        ageInput = "${data}";
      };
    in
    {
      decrypt = runCommand "test-age-decrypt" { nativeBuildInputs = [ age-decrypt ]; } ''
        age-decrypt-data --identity ${identity} >data.txt
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
