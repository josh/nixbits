{ config, lib, ... }:
let
  inherit (config) history;
  count =
    description:
    lib.mkOption {
      type = lib.types.nullOr lib.types.ints.unsigned;
      default = null;
      inherit description;
    };
in
{
  options.history = {
    enable = lib.mkEnableOption "applying the configured zsh history settings";
    size = count "Maximum history entries kept in memory.";
    save = count "Maximum history entries saved on disk.";
    options = lib.mkOption {
      type = lib.types.attrsOf lib.types.bool;
      default = { };
      description = "Zsh history options to set (true) or unset (false). Omitted options are inherited.";
    };
  };
  config.history.enable = lib.mkDefault (
    history.size != null || history.save != null || history.options != { }
  );
  config.zshrc.content = lib.mkIf history.enable (
    lib.mkOrder 1200 (
      lib.concatStringsSep "\n" (
        lib.optional (history.size != null) "HISTSIZE=${toString history.size}"
        ++ lib.optional (history.save != null) "SAVEHIST=${toString history.save}"
        ++ lib.mapAttrsToList (
          name: value: "${if value then "setopt" else "unsetopt"} ${lib.escapeShellArg name}"
        ) history.options
      )
    )
  );
}
