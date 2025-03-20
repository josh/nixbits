{
  lib,
  writeText,
  tmuxPlugins,
  nur,
  nixbits,
  theme ? null,
}:
let
  defaultTheme = ''
    run-shell '${nixbits.tmux-env-theme}/share/tmux-plugins/env-theme.tmux'
  '';
  loadThemes = {
    "tokyonight_day" = ''
      set-option -g @theme_variation 'day'
      run-shell '${nur.repos.josh.tmux-tokyo-night}/share/tmux-plugins/tmux-tokyo-night/tmux-tokyo-night.tmux'
    '';
    "tokyonight_moon" = ''
      set-option -g @theme_variation 'moon'
      run-shell '${nur.repos.josh.tmux-tokyo-night}/share/tmux-plugins/tmux-tokyo-night/tmux-tokyo-night.tmux'
    '';
    "tokyonight_storm" = ''
      set-option -g @theme_variation 'storm'
      run-shell '${nur.repos.josh.tmux-tokyo-night}/share/tmux-plugins/tmux-tokyo-night/tmux-tokyo-night.tmux'
    '';
    "tokyonight_night" = ''
      set-option -g @theme_variation 'night'
      run-shell '${nur.repos.josh.tmux-tokyo-night}/share/tmux-plugins/tmux-tokyo-night/tmux-tokyo-night.tmux'
    '';
    "catppuccin_frappe" = ''
      set-option -g @catppuccin_flavor 'frappe'
      run-shell '${nur.repos.josh.tmux-catppuccin}/share/tmux-plugins/catppuccin/catppuccin.tmux'
    '';
    "catppuccin_latte" = ''
      set-option -g @catppuccin_flavor 'latte'
      run-shell '${nur.repos.josh.tmux-catppuccin}/share/tmux-plugins/catppuccin/catppuccin.tmux'
    '';
    "catppuccin_macchiato" = ''
      set-option -g @catppuccin_flavor 'macchiato'
      run-shell '${nur.repos.josh.tmux-catppuccin}/share/tmux-plugins/catppuccin/catppuccin.tmux'
    '';
    "catppuccin_mocha" = ''
      set-option -g @catppuccin_flavor 'mocha'
      run-shell '${nur.repos.josh.tmux-catppuccin}/share/tmux-plugins/catppuccin/catppuccin.tmux'
    '';
    "rosepine_moon" = ''
      set-option -g @rose_pine_variant 'moon'
      run-shell '${nur.repos.josh.rose-pine}/share/tmux-plugins/rose-pine/rose-pine.tmux'
    '';
    "rosepine_dawn" = ''
      set-option -g @rose_pine_variant 'dawn'
      run-shell '${nur.repos.josh.rose-pine}/share/tmux-plugins/rose-pine/rose-pine.tmux'
    '';
    "rosepine" = ''
      run-shell '${nur.repos.josh.rose-pine}/share/tmux-plugins/rose-pine/rose-pine.tmux'
    '';
  };
  validThemes = builtins.attrNames loadThemes;
  loadTheme =
    if theme == null then
      defaultTheme
    else
      assert (lib.asserts.assertOneOf "theme" theme validThemes);
      loadThemes.${theme};

  ifTheme =
    themePrefix: themeConfig:
    if theme == null then
      ''
        if-shell '[ "''${THEME#${themePrefix}}" != "$THEME" ]' {
          ${themeConfig}
        }
      ''
    else if (lib.strings.hasPrefix themePrefix theme) then
      themeConfig
    else
      "";

  tokyonightConfig = ''
    set-option -g @theme_disable_plugins '1'
  '';

  catppuccinConfig = ''
    set-option -g status-position top

    # https://github.com/catppuccin/tmux#config-3

    set-option -g @catppuccin_window_left_separator ""
    set-option -g @catppuccin_window_right_separator " "
    set-option -g @catppuccin_window_middle_separator " █"
    set-option -g @catppuccin_window_number_position "right"

    set-option -g @catppuccin_window_default_fill "number"
    set-option -g @catppuccin_window_default_text "#W"

    set-option -g @catppuccin_window_current_fill "number"
    set-option -g @catppuccin_window_current_text "#W"

    set-option -g @catppuccin_status_modules_right "directory session"
    set-option -g @catppuccin_status_left_separator  " "
    set-option -g @catppuccin_status_right_separator ""
    set-option -g @catppuccin_status_fill "icon"
    set-option -g @catppuccin_status_connect_separator "no"

    set-option -g @catppuccin_directory_text "#{pane_current_path}"
  '';

in
writeText "tmux.conf" ''
  # First thing, initialize tmux sensible
  run-shell '${tmuxPlugins.sensible}/share/tmux-plugins/sensible/sensible.tmux'

  # Work around sensible issue
  #   https://github.com/tmux-plugins/tmux-sensible/blob/25cb91f/sensible.tmux#L103
  set -g default-command '$SHELL'

  # Share tmux clipboard with macOS
  run-shell '${tmuxPlugins.yank}/share/tmux-plugins/yank/yank.tmux'

  # Custom prefix key
  # Avoid conflicting with emacs bindings
  unbind-key C-b
  set-option -g prefix C-Space
  bind-key -n C-Space send-prefix

  # Mouse support
  set-option -g mouse on

  # Fix neovim colors
  set-option -g default-terminal "tmux-256color"
  set-option -sa terminal-features "$TERM:RGB"

  # Enable vi in copy mode
  set-window-option -g mode-keys vi
  bind-key -T copy-mode-vi v send -X begin-selection
  bind-key -T copy-mode-vi C-v send -X rectangle-toggle
  bind-key -T copy-mode-vi y send -X copy-selection-and-cancel

  # Pane and window indexing
  set-option -g base-index 1
  set-option -g pane-base-index 1
  set-window-option -g pane-base-index 1
  set-option -g renumber-windows on

  # Pane and window management
  bind-key c new-window -c '#{pane_current_path}'
  bind-key '"' split-window -v -c '#{pane_current_path}'
  bind-key % split-window -h -c '#{pane_current_path}'

  # Smart pane switching with awareness of Vim splits.
  # See: https://github.com/christoomey/vim-tmux-navigator
  is_vim="ps -o state= -o comm= -t '#{pane_tty}' \
      | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|l?n?vim?x?|fzf)(diff)?$'"
  bind-key h if-shell "$is_vim" 'send-keys C-w h' 'select-pane -L'
  bind-key j if-shell "$is_vim" 'send-keys C-w j' 'select-pane -D'
  bind-key k if-shell "$is_vim" 'send-keys C-w k' 'select-pane -U'
  bind-key l if-shell "$is_vim" 'send-keys C-w l' 'select-pane -R'

  # iTerm wants this off
  set-window-option -g aggressive-resize off

  ${ifTheme "tokyonight" tokyonightConfig}
  ${ifTheme "catppuccin" catppuccinConfig}
  ${loadTheme}
''
