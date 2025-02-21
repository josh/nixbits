{
  lib,
  writeShellApplication,
  nixbits,
  screenSharingUser ? "",
  screenSharingPasswordCommand ? "",
  screenSharingHostname ? "",
}:
writeShellApplication {
  name =
    if screenSharingHostname != "" then "screen-sharing-${screenSharingHostname}" else "screen-sharing";
  runtimeEnv = {
    PATH = lib.strings.makeBinPath [
      nixbits.darwin.open
      nixbits.tailscale-lan-ip
    ];
    SCREEN_SHARING_USER = screenSharingUser;
    SCREEN_SHARING_PASSWORD = "";
    SCREEN_SHARING_PASSWORD_COMMAND = screenSharingPasswordCommand;
    SCREEN_SHARING_HOSTNAME = screenSharingHostname;
  };
  text = builtins.readFile ./screen-sharing.bash;
  meta = {
    description = "Launch macOS Screen Sharing";
    platforms = lib.platforms.darwin;
  };
}
