{
  lib,
  writeShellApplication,
  runCommand,
  nixbits,
}:
let
  json2plist = writeShellApplication {
    name = "json2plist";
    runtimeInputs = [ nixbits.darwin.plutil ];
    inheritPath = false;
    text = ''
      exec plutil -convert xml1 -o - -- -
    '';
    meta = {
      description = "Convert a JSON file to a plist file";
      license = lib.licenses.mit;
      platforms = lib.platforms.darwin;
    };
  };
in
json2plist.overrideAttrs (
  finalAttrs: _previousAttrs: {
    passthru.tests =
      let
        json2plist' = finalAttrs.finalPackage;
        jsonFile = builtins.toFile "foo.json" ''
          {"foo":"bar"}
        '';
        plistFile = builtins.toFile "foo.plist" ''
          <?xml version="1.0" encoding="UTF-8"?>
          <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
          <plist version="1.0">
          <dict>
          	<key>foo</key>
          	<string>bar</string>
          </dict>
          </plist>
        '';
      in
      {
        convert-file = runCommand "test-json2plist-convert-file" { nativeBuildInputs = [ json2plist' ]; } ''
          expected="$(<${plistFile})"
          actual="$(json2plist <${jsonFile})"
          if [[ "$actual" != "$expected" ]]; then
            echo "expected, '$expected' but was '$actual'"
            exit 1
          fi
          touch $out
        '';

        convert-pipe = runCommand "test-json2plist-convert-pipe" { nativeBuildInputs = [ json2plist' ]; } ''
          expected="$(<${plistFile})"
          actual="$(cat ${jsonFile} | json2plist)"
          if [[ "$actual" != "$expected" ]]; then
            echo "expected, '$expected' but was '$actual'"
            exit 1
          fi
          touch $out
        '';

        convert-types =
          runCommand "test-json2plist-convert-types" { nativeBuildInputs = [ json2plist' ]; }
            ''
              printf '{"int":42,"real":1.5,"yes":true,"list":[1,"two"]}' >types.json
              json2plist <types.json >types.plist
              grep --quiet '<integer>42</integer>' types.plist
              grep --quiet '<real>1.5</real>' types.plist
              grep --quiet '<true/>' types.plist
              grep --quiet '<string>two</string>' types.plist
              touch $out
            '';

        error-empty = runCommand "test-json2plist-error-empty" { nativeBuildInputs = [ json2plist' ]; } ''
          if json2plist </dev/null >/dev/null 2>&1; then
            echo "expected empty input to fail"
            exit 1
          fi
          touch $out
        '';

        error-invalid =
          runCommand "test-json2plist-error-invalid" { nativeBuildInputs = [ json2plist' ]; }
            ''
              if printf '{"unterminated"' | json2plist >/dev/null 2>&1; then
                echo "expected invalid JSON to fail"
                exit 1
              fi
              touch $out
            '';
      };
  }
)
