{
  lib,
  writeShellApplication,
  runCommand,
  yq-go,
  jq,
}:
let
  xml2json = writeShellApplication {
    name = "xml2json";
    runtimeInputs = [ yq-go ];
    inheritPath = false;
    text = ''
      exec yq --input-format=xml --output-format=json
    '';
    meta = {
      description = "Convert XML to JSON";
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
                return 1
              fi
              touch $out
            '';
      };
  }
)
