{
  lib,
  stdenvNoCC,
  makeWrapper,
  lndir,
  jujutsu,
  lazyjj,
  nixbits,
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
  inherit (lazyjj')
    name
    pname
    version
    meta
    ;

  __structuredAttrs = true;

  makeWrapperArgs = [
    "--prefix"
    "PATH"
    ":"
    (lib.strings.makeBinPath [ jujutsu ])
  ]
  ++ [
    "--set"
    "JJ_CONFIG"
    "${nixbits.jujutsu-config}"
  ]
  ++ [
    "--set"
    "XDG_CONFIG_HOME"
    "${nixbits.jujutsu-xdg-config-home}"
  ];

  nativeBuildInputs = [
    makeWrapper
    lndir
  ];

  # <https://github.com/Cretezy/lazyjj/commit/523c422e6bc4c86fffcdd68eb3900085dcf23e19>
  disableCSI =
    assert lib.asserts.assertMsg (
      (builtins.compareVersions "0.6.1" lazyjj.version) == 0
    ) "lazyjj CSI patch no longer needed";
    ''
      printf '\033[<u'
    '';

  buildCommand = ''
    mkdir $out
    lndir -silent ${lazyjj'} $out

    rm $out/bin/lazyjj
    makeWrapper ${lazyjj'}/bin/lazyjj $out/bin/lazyjj "''${makeWrapperArgs[@]}"
    sed -i 's/^exec //' $out/bin/lazyjj
    echo "$disableCSI" >>$out/bin/lazyjj
  '';
}
