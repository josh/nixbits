{
  lib,
  swiftPackages,
  swift,
}:
let
  infoPlist = builtins.toFile "Info.plist" ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>CFBundleIdentifier</key>
      <string>com.joshpeek.clean-completed-reminders</string>
      <key>CFBundleName</key>
      <string>clean-completed-reminders</string>
      <key>NSRemindersFullAccessUsageDescription</key>
      <string>Delete completed reminders from Reminders.app</string>
      <key>NSRemindersUsageDescription</key>
      <string>Delete completed reminders from Reminders.app</string>
    </dict>
    </plist>
  '';
in
swiftPackages.stdenv.mkDerivation {
  name = "clean-completed-reminders";

  __structuredAttrs = true;

  dontUnpack = true;

  nativeBuildInputs = [
    swift
  ];

  buildPhase = ''
    runHook preBuild
    swiftc ${./clean-completed-reminders.swift} \
      -Xlinker -sectcreate -Xlinker __TEXT -Xlinker __info_plist -Xlinker ${infoPlist} \
      -o main
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 main $out/bin/clean-completed-reminders
    runHook postInstall
  '';

  meta = {
    description = "Delete completed reminders from Reminders.app";
    license = lib.licenses.mit;
    mainProgram = "clean-completed-reminders";
    platforms = lib.platforms.darwin;
  };
}
