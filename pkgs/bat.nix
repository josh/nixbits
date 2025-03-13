{
  stdenvNoCC,
  makeWrapper,
  testers,
  runCommand,
  lndir,
  bat,
  nixbits,
  theme ? null,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = if theme != null then "${bat.pname}-${theme}" else bat.pname;
  inherit (bat) version;

  __structuredAttrs = true;

  nativeBuildInputs = [
    makeWrapper
    lndir
  ];

  makeWrapperArgs = [ ];

  tmtheme = if theme != null then nixbits.tmtheme.override { inherit theme; } else null;
  themeName = if theme != null then finalAttrs.tmtheme.meta.name else null;

  buildCommand = ''
    mkdir -p $out
    lndir -silent ${bat} $out

    appendToVar makeWrapperArgs "--set" BAT_CONFIG_DIR "$out/etc/bat"
    appendToVar makeWrapperArgs "--set" BAT_CONFIG_PATH "$out/etc/bat/config"
    appendToVar makeWrapperArgs "--set" BAT_CACHE_PATH "$out/var/cache/bat"

    if [ -n "$themeName" ]; then
      appendToVar makeWrapperArgs "--set" BAT_THEME "$themeName"
    fi

    rm $out/bin/bat
    makeWrapper ${bat}/bin/bat $out/bin/bat "''${makeWrapperArgs[@]}"

    mkdir -p $out/etc/bat/themes $out/etc/bat/syntaxes
    touch $out/etc/bat/config

    if [ -e "$tmtheme" ] && [ -n "$themeName" ]; then
      ln -s "$tmtheme" "$out/etc/bat/themes/$themeName.tmTheme"
    fi

    $out/bin/bat cache --build
    sed -i 's/secs_since_epoch: [0-9]*/secs_since_epoch: 0/' $out/var/cache/bat/metadata.yaml
    sed -i 's/nanos_since_epoch: [0-9]*/nanos_since_epoch: 0/' $out/var/cache/bat/metadata.yaml
  '';

  passthru.tests =
    let
      bat = finalAttrs.finalPackage;
    in
    {
      version = testers.testVersion {
        package = bat;
        command = "bat --version";
        inherit (bat) version;
      };

      config-dir = runCommand "test-bat-config-dir" { nativeBuildInputs = [ bat ]; } ''
        expected="${bat}/etc/bat"
        actual="$(bat --config-dir)"
        if [[ "$actual" != "$expected" ]]; then
          echo "expected, '$expected' but was '$actual'"
          return 1
        fi
        touch $out
      '';

      config-file = runCommand "test-bat-config-file" { nativeBuildInputs = [ bat ]; } ''
        expected="${bat}/etc/bat/config"
        actual="$(bat --config-file)"
        if [[ "$actual" != "$expected" ]]; then
          echo "expected, '$expected' but was '$actual'"
          return 1
        fi
        touch $out
      '';

      cache-dir = runCommand "test-bat-cache-dir" { nativeBuildInputs = [ bat ]; } ''
        expected="${bat}/var/cache/bat"
        actual="$(bat --cache-dir)"
        if [[ "$actual" != "$expected" ]]; then
          echo "expected, '$expected' but was '$actual'"
          return 1
        fi
        touch $out
      '';
    };

  meta = {
    inherit (bat.meta) description license platforms;
    mainProgram = "bat";
  };
})
