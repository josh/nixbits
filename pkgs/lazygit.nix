{
  lib,
  formats,
  stdenvNoCC,
  makeWrapper,
  runCommand,
  git,
  lazygit,
  nixbits,
  git-config ? nixbits.git-config,
  # TODO: Detect this via env var
  useNerdFonts ? false,
}:
let
  yaml = formats.yaml { };

  config = yaml.generate "lazygit-config.yml" (
    {
      update.method = "never";
      disableStartupPopups = true;
    }
    // (lib.attrsets.optionalAttrs useNerdFonts {
      gui.nerdFontsVersion = "3";
    })
  );

  runtimePath = lib.strings.makeBinPath [
    git
  ];
in
stdenvNoCC.mkDerivation (finalAttrs: {
  __structuredAttrs = true;

  pname = "lazygit";
  inherit (lazygit) version;

  nativeBuildInputs = [ makeWrapper ];
  makeWrapperArgs =
    [
      "--set"
      "PATH"
      runtimePath
    ]
    ++ [
      "--set"
      "GIT_CONFIG_GLOBAL"
      git-config
    ]
    ++ [
      "--set"
      "LG_CONFIG_FILE"
      config
    ];

  buildCommand = ''
    mkdir -p $out/bin
    makeWrapper ${lib.getExe lazygit} $out/bin/lazygit \
      "''${makeWrapperArgs[@]}"
  '';

  meta = {
    mainProgram = "lazygit";
    inherit (lazygit.meta)
      description
      homepage
      license
      platforms
      ;
  };

  passthru.tests =
    let
      lazygit = finalAttrs.finalPackage;
    in
    {
      help = runCommand "test-lazygit-help" { nativeBuildInputs = [ lazygit ]; } ''
        lazygit --help
        touch $out
      '';
    };
})
