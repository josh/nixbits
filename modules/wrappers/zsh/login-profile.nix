{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkDefault;
  inherit (pkgs.stdenv.hostPlatform) isDarwin;
in
{
  options = {
    zprofile.content = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = ''
        Login shell setup emitted by the nixbits zsh-login package for ~/.zprofile.
        The wrapped zsh does not read it, since nix-wrapper-modules has no .zprofile.
      '';
    };
    loginProfile.enable = lib.mkEnableOption "the nixbits zsh-login defaults";
    nixDaemon.enable = lib.mkEnableOption "the multi-user Nix daemon profile in login shells";
    goPath.enable = lib.mkEnableOption "an XDG data GOPATH in login shells";
    zedEditor.enable = lib.mkEnableOption "Zed as EDITOR in login shells started by Zed's terminal";
  };

  config = lib.mkMerge [
    (lib.mkIf config.loginProfile.enable {
      nixDaemon.enable = mkDefault true;
      goPath.enable = mkDefault true;
      zedEditor.enable = mkDefault isDarwin;
      sshKeychainProvider.enable = mkDefault isDarwin;
    })
    {
      zprofile.content = lib.mkMerge [
        # Before everything else, so later setup can find Nix-installed tools.
        (lib.mkIf config.nixDaemon.enable (
          lib.mkBefore ''
            if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
              # shellcheck disable=SC1091
              . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
            fi
          ''
        ))
        (lib.mkIf config.goPath.enable ''
          export GOPATH="''${XDG_DATA_HOME:-$HOME/.local/share}/go"
        '')
        (lib.mkIf (isDarwin && config.zedEditor.enable) (
          lib.mkOrder 1600 ''
            if [ -n "$ZED_TERM" ]; then
              export EDITOR="${pkgs.nixbits.zed-cli}/bin/zed --wait"
            fi
          ''
        ))
      ];
    }
  ];
}
