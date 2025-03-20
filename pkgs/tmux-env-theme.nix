{
  lib,
  stdenvNoCC,
  writeShellScript,
  tmuxPlugins,
  nur,
}:
let
  script = writeShellScript "theme.tmux" ''
    case "''${THEME:-}" in
    tokyonight_day)
      tmux set-option -g '@theme_variation' 'day'
      source ${nur.repos.josh.tmux-tokyo-night}/share/tmux-plugins/tmux-tokyo-night/tmux-tokyo-night.tmux
      ;;
    tokyonight_moon)
      tmux set-option -g '@theme_variation' 'moon'
      source ${nur.repos.josh.tmux-tokyo-night}/share/tmux-plugins/tmux-tokyo-night/tmux-tokyo-night.tmux
      ;;
    tokyonight_storm)
      tmux set-option -g '@theme_variation' 'storm'
      source ${nur.repos.josh.tmux-tokyo-night}/share/tmux-plugins/tmux-tokyo-night/tmux-tokyo-night.tmux
      ;;
    tokyonight_night)
      tmux set-option -g '@theme_variation' 'night'
      source ${nur.repos.josh.tmux-tokyo-night}/share/tmux-plugins/tmux-tokyo-night/tmux-tokyo-night.tmux
      ;;
    tokyonight*)
      source ${nur.repos.josh.tmux-tokyo-night}/share/tmux-plugins/tmux-tokyo-night/tmux-tokyo-night.tmux
      ;;
    catppuccin_frappe)
      tmux set-option -g '@catppuccin_flavor' 'frappe'
      source ${nur.repos.josh.tmux-catppuccin}/share/tmux-plugins/catppuccin/catppuccin.tmux
      ;;
    catppuccin_latte)
      tmux set-option -g '@catppuccin_flavor' 'latte'
      source ${nur.repos.josh.tmux-catppuccin}/share/tmux-plugins/catppuccin/catppuccin.tmux
      ;;
    catppuccin_macchiato)
      tmux set-option -g '@catppuccin_flavor' 'macchiato'
      source ${nur.repos.josh.tmux-catppuccin}/share/tmux-plugins/catppuccin/catppuccin.tmux
      ;;
    catppuccin_mocha)
      tmux set-option -g '@catppuccin_flavor' 'mocha'
      source ${nur.repos.josh.tmux-catppuccin}/share/tmux-plugins/catppuccin/catppuccin.tmux
      ;;
    catppuccin*)
      source ${nur.repos.josh.tmux-catppuccin}/share/tmux-plugins/catppuccin/catppuccin.tmux
      ;;
    rosepine_moon)
      tmux set-option -g '@rose_pine_variant' 'moon'
      source ${tmuxPlugins.rose-pine}/share/tmux-plugins/rose-pine/rose-pine.tmux
      ;;
    rosepine_dawn)
      tmux set-option -g '@rose_pine_variant' 'dawn'
      source ${tmuxPlugins.rose-pine}/share/tmux-plugins/rose-pine/rose-pine.tmux
      ;;
    rosepine*)
      source ${tmuxPlugins.rose-pine}/share/tmux-plugins/rose-pine/rose-pine.tmux
      ;;
    esac
  '';
in
stdenvNoCC.mkDerivation {
  name = "tmux-env-theme";

  buildCommand = ''
    mkdir -p $out/share/tmux-plugins
    install -m 555 ${script} $out/share/tmux-plugins/env-theme.tmux
  '';

  meta = {
    description = "tmux theme based on $THEME";
    platforms = lib.platforms.unix;
  };
}
