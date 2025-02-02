{
  stdenvNoCC,
  runCommand,
  makeWrapper,
  python3,
  jq,
}:
let
  inherit (python3.pkgs.llm) version;
  venv =
    (python3.withPackages (
      ps: with ps; [
        llm
        llm-cmd
        llm-gguf
        llm-ollama
      ]
    )).overrideAttrs
      {
        pname = "llm-venv";
        inherit version;
      };
in
stdenvNoCC.mkDerivation (finalAttrs: {
  __structuredAttrs = true;

  pname = "llm";
  inherit version;

  nativeBuildInputs = [ makeWrapper ];
  makeWrapperArgs = [ ];

  buildCommand = ''
    mkdir -p $out/bin
    makeWrapper ${venv}/bin/llm $out/bin/llm "''${makeWrapperArgs[@]}"
  '';

  meta = {
    mainProgram = "llm";
    inherit (python3.pkgs.llm.meta)
      description
      homepage
      license
      platforms
      ;
  };

  passthru.tests =
    let
      llm = finalAttrs.finalPackage;
    in
    {
      help =
        runCommand "test-llm-help"
          {
            nativeBuildInputs = [
              llm
            ];
          }
          ''
            llm --help
            touch $out
          '';

      plugins =
        runCommand "test-llm-plugins"
          {
            nativeBuildInputs = [
              llm
              jq
            ];
          }
          ''
            llm plugins | jq --exit-status 'map(select(.name == "llm-ollama")) | length > 0'
            touch $out
          '';
    };
})
