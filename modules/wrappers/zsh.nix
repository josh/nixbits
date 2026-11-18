{
  config,
  lib,
  pkgs,
  wlib,
  ...
}:
{
  imports = [ wlib.wrapperModules.zsh ];

  options = {
    zoxide.enable = lib.mkEnableOption "zoxide shell integration";
    zp.enable = lib.mkEnableOption "the zp project navigation function";
    zp.package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.nixbits.zp-zsh;
      description = "Sourceable zp function with the desired Git and Jujutsu commands.";
    };
  };

  config = {
    # zp uses z to enter a checkout. Consumers can also supply their own z.
    zoxide.enable = lib.mkIf config.zp.enable (lib.mkDefault true);
    zshrc.content = lib.mkMerge [
      (lib.mkIf config.zoxide.enable (lib.mkAfter "source ${pkgs.nixbits.zoxide-init-zsh}"))
      (lib.mkIf config.zp.enable (lib.mkAfter "source ${config.zp.package}"))
    ];
  };
}
