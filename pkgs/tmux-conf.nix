{
  lib,
  writeText,
  tmuxPlugins,
  nur,
  theme ? null,
}:
let
  validThemes = builtins.attrNames loadThemes;

  loadTheme =
    if theme == null then
      envTheme
    else
      assert (lib.asserts.assertOneOf "theme" theme validThemes);
      loadThemes.${theme};

  loadThemes = {
    "tokyonight_day" = ''
      set-option -g @theme_variation 'day'
      ${tokyonightConfig}
      run-shell '${nur.repos.josh.tmux-tokyo-night}/share/tmux-plugins/tmux-tokyo-night/tmux-tokyo-night.tmux'
    '';
    "tokyonight_moon" = ''
      set-option -g @theme_variation 'moon'
      ${tokyonightConfig}
      run-shell '${nur.repos.josh.tmux-tokyo-night}/share/tmux-plugins/tmux-tokyo-night/tmux-tokyo-night.tmux'
    '';
    "tokyonight_storm" = ''
      set-option -g @theme_variation 'storm'
      ${tokyonightConfig}
      run-shell '${nur.repos.josh.tmux-tokyo-night}/share/tmux-plugins/tmux-tokyo-night/tmux-tokyo-night.tmux'
    '';
    "tokyonight_night" = ''
      set-option -g @theme_variation 'night'
      ${tokyonightConfig}
      run-shell '${nur.repos.josh.tmux-tokyo-night}/share/tmux-plugins/tmux-tokyo-night/tmux-tokyo-night.tmux'
    '';
    "catppuccin_frappe" = ''
      set-option -g @catppuccin_flavor 'frappe'
      ${catppuccinConfig}
      run-shell '${nur.repos.josh.tmux-catppuccin}/share/tmux-plugins/catppuccin/catppuccin.tmux'
    '';
    "catppuccin_latte" = ''
      set-option -g @catppuccin_flavor 'latte'
      ${catppuccinConfig}
      run-shell '${nur.repos.josh.tmux-catppuccin}/share/tmux-plugins/catppuccin/catppuccin.tmux'
    '';
    "catppuccin_macchiato" = ''
      set-option -g @catppuccin_flavor 'macchiato'
      ${catppuccinConfig}
      run-shell '${nur.repos.josh.tmux-catppuccin}/share/tmux-plugins/catppuccin/catppuccin.tmux'
    '';
    "catppuccin_mocha" = ''
      set-option -g @catppuccin_flavor 'mocha'
      ${catppuccinConfig}
      run-shell '${nur.repos.josh.tmux-catppuccin}/share/tmux-plugins/catppuccin/catppuccin.tmux'
    '';
    "rosepine_moon" = ''
      set-option -g @rose_pine_variant 'moon'
      run-shell ${tmuxPlugins.rose-pine}/share/tmux-plugins/rose-pine/rose-pine.tmux
    '';
    "rosepine_dawn" = ''
      set-option -g @rose_pine_variant 'dawn'
      run-shell ${tmuxPlugins.rose-pine}/share/tmux-plugins/rose-pine/rose-pine.tmux
    '';
    "rosepine" = ''
      run-shell ${tmuxPlugins.rose-pine}/share/tmux-plugins/rose-pine/rose-pine.tmux
    '';
  };

  envTheme = ''
    if-shell '[ "$THEME" = "tokyonight_day" ]' {
      ${loadThemes.tokyonight_day}
    }
    if-shell '[ "$THEME" = "tokyonight_moon" ]' {
      ${loadThemes.tokyonight_moon}
    }
    if-shell '[ "$THEME" = "tokyonight_storm" ]' {
      ${loadThemes.tokyonight_storm}
    }
    if-shell '[ "$THEME" = "tokyonight_night" ]' {
      ${loadThemes.tokyonight_night}
    }
    if-shell '[ "$THEME" = "catppuccin_frappe" ]' {
      ${loadThemes.catppuccin_frappe}
    }
    if-shell '[ "$THEME" = "catppuccin_latte" ]' {
      ${loadThemes.catppuccin_latte}
    }
    if-shell '[ "$THEME" = "catppuccin_macchiato" ]' {
      ${loadThemes.catppuccin_macchiato}
    }
    if-shell '[ "$THEME" = "catppuccin_mocha" ]' {
      ${loadThemes.catppuccin_mocha}
    }
    if-shell '[ "$THEME" = "rosepine_moon" ]' {
      ${loadThemes.rosepine_moon}
    }
    if-shell '[ "$THEME" = "rosepine_dawn" ]' {
      ${loadThemes.rosepine_dawn}
    }
    if-shell '[ "$THEME" = "rosepine" ]' {
      ${loadThemes.rosepine}
    }
  '';

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

  # Theme
  ${loadTheme}
''
