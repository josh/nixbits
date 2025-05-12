{
  lib,
  writeShellApplication,
  runCommand,
  yq-go,
  jq,
}:
let
  csv2json = writeShellApplication {
    name = "csv2json";
    runtimeInputs = [ yq-go ];
    inheritPath = false;
    text = ''
      exec yq --input-format=csv --output-format=json
    '';
    meta = {
      description = "Convert CSV to JSON";
      platforms = lib.platforms.all;
    };
  };
in
csv2json.overrideAttrs (
  finalAttrs: _previousAttrs: {
    passthru.tests =
      let
        csv2json = finalAttrs.finalPackage;
        jsonFile = builtins.toFile "foo.json" ''
          [{"foo":"bar"}]
        '';
        csvFile = builtins.toFile "foo.csv" ''
          foo
          bar
        '';
      in
      {
        convert =
          runCommand "test-csv2json-convert"
            {
              nativeBuildInputs = [
                csv2json
                jq
              ];
            }
            ''
              expected="$(<${jsonFile})"
              actual="$(csv2json <${csvFile} | jq --compact-output)"
              if [[ "$actual" != "$expected" ]]; then
                echo "expected, '$expected' but was '$actual'"
                return 1
              fi
              touch $out
            '';
      };
  }
)
