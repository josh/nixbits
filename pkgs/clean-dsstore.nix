{
  lib,
  stdenvNoCC,
  writeShellScript,
  findutils,
}:
let
  script = writeShellScript "clean-dsstore" ''
    set -o errexit
    ${findutils}/bin/find . -type f -name ".DS_Store" -print -delete
  '';
in
stdenvNoCC.mkDerivation {
  name = "clean-dsstore";

  buildCommand = ''
    mkdir -p $out/bin
    install -m 755 ${script} $out/bin/clean-dsstore
    install -m 755 ${script} $out/bin/dsunhook
  '';

  meta = {
    description = "Clean .DS_Store files recursively";
    mainProgram = "clean-dsstore";
    platforms = lib.platforms.darwin;
  };
}
