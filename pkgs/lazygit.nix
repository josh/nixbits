{
  lib,
  stdenvNoCC,
  formats,
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
  pname = "lazygit";
  inherit (lazygit) version;

  __structuredAttrs = true;

  nativeBuildInputs = [ makeWrapper ];
  makeWrapperArgs = [
    "--set"
    "PATH"
    runtimePath
    "--set"
    "GIT_CONFIG_GLOBAL"
    git-config
    "--set"
    "LG_CONFIG_FILE"
    config
  ];

  buildCommand = ''
    mkdir -p $out/bin
    makeWrapper ${lib.getExe lazygit} $out/bin/lazygit \
      "''${makeWrapperArgs[@]}"
  '';

  passthru.tests =
    let
      lazygit = finalAttrs.finalPackage;
    in
    {
      help = runCommand "test-lazygit-help" { nativeBuildInputs = [ lazygit ]; } ''
        lazygit --help
        touch $out
      '';

      config = runCommand "test-lazygit-config" { } ''
        grep --quiet 'disableStartupPopups: true' ${config}
        grep --quiet 'method: never' ${config}
        touch $out
      '';

      wrapper-env = runCommand "test-lazygit-wrapper-env" { } ''
        grep --quiet 'GIT_CONFIG_GLOBAL.*${git-config}' ${lazygit}/bin/lazygit
        grep --quiet 'LG_CONFIG_FILE.*${config}' ${lazygit}/bin/lazygit
        grep --quiet 'PATH.*${runtimePath}' ${lazygit}/bin/lazygit
        touch $out
      '';
    };

  meta = {
    inherit (lazygit.meta)
      description
      homepage
      license
      platforms
      ;
    mainProgram = "lazygit";
  };
})
