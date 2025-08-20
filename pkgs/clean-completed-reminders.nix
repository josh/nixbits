{
  lib,
  swiftPackages,
  swift,
}:
swiftPackages.stdenv.mkDerivation {
  name = "clean-completed-reminders";

  dontUnpack = true;

  nativeBuildInputs = [
    swift
  ];

  buildPhase = ''
    swiftc ${./clean-completed-reminders.swift} -o main
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 main $out/bin/clean-completed-reminders
    runHook postInstall
  '';

  meta = {
    mainProgram = "clean-completed-reminders";
    platforms = lib.platforms.darwin;
  };
}
