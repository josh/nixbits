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
      ${tokyonightConfigPre}
      run-shell '${nur.repos.josh.tmux-tokyo-night}/share/tmux-plugins/tmux-tokyo-night/tmux-tokyo-night.tmux'
    '';
    "tokyonight_moon" = ''
      set-option -g @theme_variation 'moon'
      ${tokyonightConfigPre}
      run-shell '${nur.repos.josh.tmux-tokyo-night}/share/tmux-plugins/tmux-tokyo-night/tmux-tokyo-night.tmux'
    '';
    "tokyonight_storm" = ''
      set-option -g @theme_variation 'storm'
      ${tokyonightConfigPre}
      run-shell '${nur.repos.josh.tmux-tokyo-night}/share/tmux-plugins/tmux-tokyo-night/tmux-tokyo-night.tmux'
    '';
    "tokyonight_night" = ''
      set-option -g @theme_variation 'night'
      ${tokyonightConfigPre}
      run-shell '${nur.repos.josh.tmux-tokyo-night}/share/tmux-plugins/tmux-tokyo-night/tmux-tokyo-night.tmux'
    '';
    "catppuccin_frappe" = ''
      set-option -g @catppuccin_flavor 'frappe'
      set-option -g @catppuccin_status_background '#303446'
      ${catppuccinConfigPre}
      run-shell '${nur.repos.josh.tmux-catppuccin}/share/tmux-plugins/catppuccin/catppuccin.tmux'
      ${catppuccinConfigPost}
    '';
    "catppuccin_latte" = ''
      set-option -g @catppuccin_flavor 'latte'
      set-option -g @catppuccin_status_background '#eff1f5'
      ${catppuccinConfigPre}
      run-shell '${nur.repos.josh.tmux-catppuccin}/share/tmux-plugins/catppuccin/catppuccin.tmux'
      ${catppuccinConfigPost}
    '';
    "catppuccin_macchiato" = ''
      set-option -g @catppuccin_flavor 'macchiato'
      set-option -g @catppuccin_status_background '#24273a'
      ${catppuccinConfigPre}
      run-shell '${nur.repos.josh.tmux-catppuccin}/share/tmux-plugins/catppuccin/catppuccin.tmux'
      ${catppuccinConfigPost}
    '';
    "catppuccin_mocha" = ''
      set-option -g @catppuccin_flavor 'mocha'
      set-option -g @catppuccin_status_background '#1e1e2e'
      ${catppuccinConfigPre}
      run-shell '${nur.repos.josh.tmux-catppuccin}/share/tmux-plugins/catppuccin/catppuccin.tmux'
      ${catppuccinConfigPost}
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

  tokyonightConfigPre = ''
    set-option -g @theme_disable_plugins '1'
  '';

  catppuccinConfigPre = ''
    set-option -g @catppuccin_window_status_style 'rounded'

    # Only disable dirname for other windows
    # set-option -g @catppuccin_window_current_text " #{b:pane_current_path}"
    set-option -g @catppuccin_window_text " #{b:pane_current_path}"
  '';
  catppuccinConfigPost = ''
    set-option -g status-right-length 100
    set-option -g status-left-length 100
    set-option -g status-right ""
    set-option -g status-left ""

    set-option -ag status-right "#{E:@catppuccin_status_application}"
    set-option -ag status-right "#{E:@catppuccin_status_session}"
    set-option -ag status-right "#{E:@catppuccin_status_uptime}"  
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

  # Theme
  ${loadTheme}

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
''
