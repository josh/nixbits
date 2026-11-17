{
  lib,
  stdenvNoCC,
  lndir,
  makeWrapper,
  runCommand,
  writeShellScriptBin,
  writeText,
  jujutsu,
  lazyjj,
  nixbits,
  git-config ? nixbits.git-config,
  jujutsu-config ? nixbits.jujutsu-config,
}:
let
  lazyjj' = lazyjj.overrideAttrs {
    # Disable wrapProgram
    postInstall = "";
    # Disable tests that fail due to jj version incompatibility
    doCheck = false;
  };
in
stdenvNoCC.mkDerivation {
  inherit (lazyjj') pname version;

  __structuredAttrs = true;

  nativeBuildInputs = [
    lndir
    makeWrapper
  ];

  makeWrapperArgs = [
    "--prefix"
    "PATH"
    ":"
    (lib.strings.makeBinPath [ jujutsu ])
    "--set"
    "JJ_CONFIG"
    "${jujutsu-config}"
    "--set"
    "GIT_CONFIG_GLOBAL"
    "${git-config}"
  ];

  # <https://github.com/Cretezy/lazyjj/commit/523c422e6bc4c86fffcdd68eb3900085dcf23e19>
  disableCSI =
    if (lib.strings.versionOlder lazyjj.version "0.6.2") then
      ''
        printf '\033[<u'
      ''
    else
      "";

  buildCommand = ''
    mkdir $out
    lndir -silent ${lazyjj'} $out

    rm $out/bin/lazyjj
    makeWrapper ${lazyjj'}/bin/lazyjj $out/bin/lazyjj "''${makeWrapperArgs[@]}"
    sed -i 's/^exec //' $out/bin/lazyjj
    echo "$disableCSI" >>$out/bin/lazyjj
  '';

  passthru.tests.config-overrides =
    let
      probe =
        (writeShellScriptBin "lazyjj" ''
          set -eu
          printf '%s\n' "$GIT_CONFIG_GLOBAL" "$JJ_CONFIG" >"$PROBE_OUTPUT"
        '').overrideAttrs
          {
            pname = "lazyjj";
            inherit (lazyjj) version;
          };
      defaultWrapper = nixbits.lazyjj.override { lazyjj = probe; };
      customGitConfig = writeText "lazyjj-git-config" ''
        [user]
        name = Override Author
      '';
      customJjConfig = writeText "lazyjj-jj-config.toml" ''
        [user]
        name = "Override Author"
      '';
      customWrapper = nixbits.lazyjj.override {
        lazyjj = probe;
        git-config = customGitConfig;
        jujutsu-config = customJjConfig;
      };
    in
    runCommand "test-lazyjj-config-overrides" { } ''
      export GIT_CONFIG_GLOBAL=/ignored/git-config JJ_CONFIG=/ignored/jj-config
      export PROBE_OUTPUT="$PWD/default-config"
      ${defaultWrapper}/bin/lazyjj >/dev/null
      test "$(cat "$PROBE_OUTPUT")" = "$(printf '%s\n' '${nixbits.git-config}' '${nixbits.jujutsu-config}')"
      export PROBE_OUTPUT="$PWD/custom-config"
      ${customWrapper}/bin/lazyjj >/dev/null
      test "$(cat "$PROBE_OUTPUT")" = "$(printf '%s\n' '${customGitConfig}' '${customJjConfig}')"
      touch $out
    '';

  inherit (lazyjj') meta;
}
