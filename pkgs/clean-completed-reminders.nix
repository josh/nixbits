{
  lib,
  swiftPackages,
  swift,
}:
swiftPackages.stdenv.mkDerivation {
  name = "clean-completed-reminders";

  __structuredAttrs = true;

  dontUnpack = true;

  nativeBuildInputs = [
    swift
  ];

  buildPhase = ''
    runHook preBuild
    swiftc ${./clean-completed-reminders.swift} -o main
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 main $out/bin/clean-completed-reminders
    runHook postInstall
  '';

  meta = {
    description = "Delete completed reminders from Reminders.app";
    mainProgram = "clean-completed-reminders";
    platforms = lib.platforms.darwin;
  };
}
