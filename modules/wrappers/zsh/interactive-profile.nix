{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkDefault;
in
{
  options.interactiveProfile.enable = lib.mkEnableOption "the nixbits zsh-interactive defaults";
  config = lib.mkIf config.interactiveProfile.enable {
    uniquePaths.enable = mkDefault true;
    rexTheme.enable = mkDefault true;
    manPager.enable = mkDefault true;
    completion.enable = mkDefault true;
    completion.profileCache = mkDefault true;
    history.size = mkDefault 50000;
    history.save = mkDefault 50000;
    history.options = lib.genAttrs [
      "EXTENDED_HISTORY"
      "APPEND_HISTORY"
      "HIST_FIND_NO_DUPS"
      "HIST_IGNORE_DUPS"
      "HIST_IGNORE_SPACE"
    ] (_: mkDefault true);
    emacsBindings.enable = mkDefault true;
    bashWordStyle.enable = mkDefault true;
    autosuggestions.enable = mkDefault true;
    direnv.enable = mkDefault true;
    direnv.beforePrompt = mkDefault true;
    direnv.addToPath = mkDefault true;
    fzf.enable = mkDefault true;
    starship.enable = mkDefault true;
    zoxide.enable = mkDefault true;
    syntaxHighlighting.enable = mkDefault true;
    ezaAliases.enable = mkDefault true;
    editorFallback.enable = mkDefault true;
    iCloudHistory.enable = mkDefault pkgs.stdenv.hostPlatform.isDarwin;
    iterm2.enable = mkDefault pkgs.stdenv.hostPlatform.isDarwin;
    sshKeychainProvider.enable = mkDefault pkgs.stdenv.hostPlatform.isDarwin;
    zp.enable = mkDefault pkgs.stdenv.hostPlatform.isDarwin;
  };
}
