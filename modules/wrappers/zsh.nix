{
  config,
  lib,
  pkgs,
  wlib,
  ...
}:
let
  direnv = lib.getExe' config.direnv.package "direnv";
  direnvHook = pkgs.runCommand "direnv-hook.zsh" { } ''
    # direnv embeds its running executable, which may be behind the configured wrapper.
    selfPath=$(${direnv} status --json | ${lib.getExe pkgs.jq} -er '.config.SelfPath')
    ${direnv} hook zsh >hook.zsh
    substitute hook.zsh "$out" --replace-fail "$selfPath" "${direnv}"
    ${pkgs.zsh}/bin/zsh -n "$out"
  '';
in
{
  imports = [ wlib.wrapperModules.zsh ];

  options = {
    direnv.enable = lib.mkEnableOption "direnv shell integration";
    direnv.package = lib.mkPackageOption pkgs.nixbits "direnv" { };
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
      (lib.mkIf config.direnv.enable (lib.mkAfter "source ${direnvHook}"))
      (lib.mkIf config.zoxide.enable (lib.mkAfter "source ${pkgs.nixbits.zoxide-init-zsh}"))
      (lib.mkIf config.zp.enable (lib.mkAfter "source ${config.zp.package}"))
    ];
  };
}
