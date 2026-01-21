{
  lib,
  python3,
  stdenvNoCC,
  runCommand,
}:
let
  python = python3.withPackages (ps: [
    ps.click
  ]);
in
stdenvNoCC.mkDerivation (finalAttrs: {
  __structuredAttrs = true;

  name = "nix-flake-dependents";

  buildCommand = ''
    mkdir -p $out/bin
    (
      echo "#!${python.interpreter}"
      cat "${./nix-flake-dependents.py}"
    ) >$out/bin/nix-flake-dependents
    chmod +x $out/bin/nix-flake-dependents
  '';

  meta = {
    mainProgram = "nix-flake-dependents";
    description = "Scan nix flake package dependents";
    platforms = lib.platforms.all;
  };

  passthru.tests =
    let
      nix-flake-dependents = finalAttrs.finalPackage;
    in
    {
      help =
        runCommand "test-nix-flake-dependents-help" { nativeBuildInputs = [ nix-flake-dependents ]; }
          ''
            nix-flake-dependents --help
            touch $out
          '';
    };
})
