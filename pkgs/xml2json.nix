{
  lib,
  writeShellApplication,
  runCommand,
  jq,
  yq-go,
}:
let
  xml2json = writeShellApplication {
    name = "xml2json";
    runtimeInputs = [ yq-go ];
    inheritPath = false;
    text = ''
      exec yq --input-format=xml --output-format=json --xml-strict-mode --xml-raw-token=false
    '';
    meta = {
      description = "Convert XML to JSON";
      license = lib.licenses.mit;
      platforms = lib.platforms.all;
    };
  };
in
xml2json.overrideAttrs (
  finalAttrs: _previousAttrs: {
    passthru.tests =
      let
        xml2json = finalAttrs.finalPackage;
        jsonFile = builtins.toFile "foo.json" ''
          {"foo":"bar"}
        '';
        xmlFile = builtins.toFile "foo.xml" ''
          <foo>bar</foo>
        '';
      in
      {
        convert =
          runCommand "test-xml2json-convert"
            {
              nativeBuildInputs = [
                xml2json
                jq
              ];
            }
            ''
              expected="$(<${jsonFile})"
              actual="$(xml2json <${xmlFile} | jq --compact-output)"
              if [[ "$actual" != "$expected" ]]; then
                echo "expected, '$expected' but was '$actual'"
                exit 1
              fi
              touch $out
            '';

        error-truncated =
          runCommand "test-xml2json-error-truncated"
            {
              nativeBuildInputs = [ xml2json ];
            }
            ''
              if printf '<a>hello' | xml2json >/dev/null 2>&1; then
                echo "expected truncated XML to fail"
                exit 1
              fi
              touch $out
            '';

        error-mismatched =
          runCommand "test-xml2json-error-mismatched"
            {
              nativeBuildInputs = [ xml2json ];
            }
            ''
              if printf '<a><b></a>' | xml2json >/dev/null 2>&1; then
                echo "expected mismatched tags to fail"
                exit 1
              fi
              touch $out
            '';
      };
  }
)
