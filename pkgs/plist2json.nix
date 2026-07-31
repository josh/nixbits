{
  lib,
  writeShellApplication,
  runCommand,
  jq,
  nixbits,
}:
let
  plist2json = writeShellApplication {
    name = "plist2json";
    runtimeInputs = [ nixbits.darwin.plutil ];
    inheritPath = false;
    text = ''
      exec plutil -convert json -o - -- -
    '';
    meta = {
      description = "Convert a plist file to a JSON file";
      platforms = lib.platforms.darwin;
    };
  };

  mkPlist =
    name: body:
    builtins.toFile "${name}.plist" ''
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      ${body}
      </plist>
    '';
in
plist2json.overrideAttrs (
  finalAttrs: _previousAttrs: {
    passthru.tests =
      let
        plist2json' = finalAttrs.finalPackage;

        mkConvertTest =
          name: body: expected:
          runCommand "test-plist2json-${name}"
            {
              nativeBuildInputs = [
                plist2json'
                jq
              ];
              plistFile = mkPlist name body;
              inherit expected;
            }
            ''
              expected="$(jq --compact-output --sort-keys <<<"$expected")"
              actual="$(plist2json <"$plistFile" | jq --compact-output --sort-keys)"
              if [[ "$actual" != "$expected" ]]; then
                echo "expected '$expected' but was '$actual'"
                return 1
              fi
              touch $out
            '';

        mkErrorTest =
          name: fixture:
          runCommand "test-plist2json-${name}"
            {
              nativeBuildInputs = [ plist2json' ];
              inherit fixture;
            }
            ''
              if plist2json <"$fixture" >/dev/null 2>&1; then
                echo "expected conversion to fail"
                return 1
              fi
              touch $out
            '';
      in
      {
        convert-string =
          mkConvertTest "string" "<dict><key>foo</key><string>bar</string></dict>"
            ''{"foo":"bar"}'';

        convert-types =
          mkConvertTest "types"
            "<dict><key>int</key><integer>42</integer><key>real</key><real>1.5</real><key>yes</key><true/><key>no</key><false/></dict>"
            ''{"int":42,"real":1.5,"yes":true,"no":false}'';

        convert-nested =
          mkConvertTest "nested"
            "<dict><key>list</key><array><integer>1</integer><string>two</string></array><key>dict</key><dict><key>inner</key><string>v</string></dict></dict>"
            ''{"list":[1,"two"],"dict":{"inner":"v"}}'';

        convert-unicode =
          mkConvertTest "unicode" "<dict><key>msg</key><string>héllo — 🎉</string></dict>"
            ''{"msg":"héllo — 🎉"}'';

        convert-binary =
          runCommand "test-plist2json-binary"
            {
              nativeBuildInputs = [
                plist2json'
                jq
                nixbits.darwin.plutil
              ];
              plistFile = mkPlist "binary" "<dict><key>foo</key><string>bar</string></dict>";
            }
            ''
              plutil -convert binary1 -o binary.plist -- "$plistFile"
              actual="$(plist2json <binary.plist | jq --compact-output --sort-keys)"
              if [[ "$actual" != '{"foo":"bar"}' ]]; then
                echo "expected '{\"foo\":\"bar\"}' but was '$actual'"
                return 1
              fi
              touch $out
            '';

        error-empty = runCommand "test-plist2json-error-empty" { nativeBuildInputs = [ plist2json' ]; } ''
          if plist2json </dev/null >/dev/null 2>&1; then
            echo "expected empty input to fail"
            return 1
          fi
          touch $out
        '';

        error-data = mkErrorTest "error-data" (
          mkPlist "data" "<dict><key>blob</key><data>aGk=</data></dict>"
        );

        error-date = mkErrorTest "error-date" (
          mkPlist "date" "<dict><key>when</key><date>2001-01-01T00:00:00Z</date></dict>"
        );
      };
  }
)
