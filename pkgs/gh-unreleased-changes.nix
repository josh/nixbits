{
  lib,
  stdenvNoCC,
  runCommand,
  python3,
  nixbits,
}:
let
  python = python3.withPackages (ps: [
    ps.click
    ps.pygithub
  ]);
in
stdenvNoCC.mkDerivation (finalAttrs: {
  name = "gh-unreleased-changes";

  __structuredAttrs = true;

  buildCommand = ''
    mkdir -p $out/bin
    (
      echo "#!${python.interpreter}"
      cat "${./gh-unreleased-changes.py}"
    ) >$out/bin/gh-unreleased-changes
    substituteInPlace $out/bin/gh-unreleased-changes \
      --replace-fail "@gh@" "${nixbits.gh}/bin/gh"
    chmod +x $out/bin/gh-unreleased-changes
  '';

  passthru.tests =
    let
      gh-unreleased-changes = finalAttrs.finalPackage;
    in
    {
      help =
        runCommand "test-gh-unreleased-changes-help" { nativeBuildInputs = [ gh-unreleased-changes ]; }
          ''
            gh-unreleased-changes --help
            touch $out
          '';
    };

  meta = {
    description = "List repositories with unreleased changes worth tagging";
    license = lib.licenses.mit;
    mainProgram = "gh-unreleased-changes";
    platforms = lib.platforms.all;
  };
})
