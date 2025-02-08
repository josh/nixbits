{
  stdenvNoCC,
  runCommand,
  makeWrapper,
  python3,
  jq,
  cacert,
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
            # Appears to be a regression in httpx cacert bundling
            # https://github.com/NixOS/nixpkgs/commit/14ec122
            SSL_CERT_FILE = "${cacert}/etc/ssl/certs/ca-bundle.crt";
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
            # Appears to be a regression in httpx cacert bundling
            # https://github.com/NixOS/nixpkgs/commit/14ec122
            SSL_CERT_FILE = "${cacert}/etc/ssl/certs/ca-bundle.crt";
          }
          ''
            llm plugins | jq --exit-status 'map(select(.name == "llm-ollama")) | length > 0'
            touch $out
          '';
    };
})
