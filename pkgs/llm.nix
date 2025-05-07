{
  stdenvNoCC,
  runCommand,
  makeWrapper,
  python3,
  cacert,
  jq,
  nur,
}:
let
  inherit (python3.pkgs.llm) version;

  inherit (nur.repos.josh) llm-sentence-transformers;
  inherit (nur.repos.josh) llm-ttok;

  venv =
    (python3.withPackages (
      ps: with ps; [
        # keep-sorted start
        llm
        llm-anthropic
        llm-cmd
        llm-gemini
        llm-gguf
        llm-jq
        llm-ollama
        llm-openai-plugin
        llm-sentence-transformers
        # keep-sorted end
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
  makeWrapperArgs = [
    # Need for ollama/httpx dependency
    "--set"
    "SSL_CERT_FILE"
    "${cacert}/etc/ssl/certs/ca-bundle.crt"
  ];

  buildCommand = ''
    mkdir -p $out/bin
    makeWrapper ${venv}/bin/llm $out/bin/llm "''${makeWrapperArgs[@]}"
    makeWrapper ${llm-ttok}/bin/ttok $out/bin/ttok
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

      ttok =
        runCommand "test-llm-ttok"
          {
            nativeBuildInputs = [
              llm
            ];
          }
          ''
            ttok --help
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
