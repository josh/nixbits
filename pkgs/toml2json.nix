{
  lib,
  writeShellApplication,
  runCommand,
  yq-go,
  jq,
}:
let
  toml2json = writeShellApplication {
    name = "toml2json";
    runtimeEnv = {
      PATH = lib.strings.makeBinPath [ yq-go ];
    };
    text = ''
      exec yq --input-format=toml --output-format=json
    '';
    meta = {
      description = "Convert TOML to JSON";
      platforms = lib.platforms.all;
    };
  };
in
toml2json.overrideAttrs (
  finalAttrs: _previousAttrs: {
    passthru.tests =
      let
        toml2json = finalAttrs.finalPackage;
        jsonFile = builtins.toFile "foo.json" ''
          {"foo":"bar"}
        '';
        tomlFile = builtins.toFile "foo.toml" ''
          foo = "bar"
        '';
      in
      {
        convert =
          runCommand "test-toml2json-convert"
            {
              nativeBuildInputs = [
                toml2json
                jq
              ];
            }
            ''
              expected="$(<${jsonFile})"
              actual="$(toml2json <${tomlFile} | jq --compact-output)"
              if [[ "$actual" != "$expected" ]]; then
                echo "expected, '$expected' but was '$actual'"
                return 1
              fi
              touch $out
            '';
      };
  }
)
