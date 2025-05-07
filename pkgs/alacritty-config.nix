{
  lib,
  stdenvNoCC,
  writers,
  catppuccin,
  yq,
  nur,
  nixbits,
  interactiveShell ? "${nixbits.zsh}/bin/zsh",
  theme ? null,
  enableTmux ? true,
}:
let
  tmuxConfig = nixbits.alacritty-tmux-config.override { inherit interactiveShell theme; };

  catppuccin-frappe = catppuccin.override { variant = "frappe"; };
  catppuccin-latte = catppuccin.override { variant = "latte"; };
  catppuccin-macchiato = catppuccin.override { variant = "macchiato"; };
  catppuccin-mocha = catppuccin.override { variant = "mocha"; };

  themeImports = {
    "catppuccin_frappe" = "${catppuccin-frappe}/alacritty/catppuccin-frappe.toml";
    "catppuccin_latte" = "${catppuccin-latte}/alacritty/catppuccin-latte.toml";
    "catppuccin_macchiato" = "${catppuccin-macchiato}/alacritty/catppuccin-macchiato.toml";
    "catppuccin_mocha" = "${catppuccin-mocha}/alacritty/catppuccin-mocha.toml";
    "rosepine_dawn" = "${nur.repos.josh.alacritty-rose-pine}/rose-pine-dawn.toml";
    "rosepine_moon" = "${nur.repos.josh.alacritty-rose-pine}/rose-pine-moon.toml";
    "rosepine" = "${nur.repos.josh.alacritty-rose-pine}/rose-pine.toml";
    "tokyonight_day" =
      "${nur.repos.josh.tokyonight-extras}/share/tokyonight/alacritty/tokyonight_day.toml";
    "tokyonight_moon" =
      "${nur.repos.josh.tokyonight-extras}/share/tokyonight/alacritty/tokyonight_moon.toml";
    "tokyonight_night" =
      "${nur.repos.josh.tokyonight-extras}/share/tokyonight/alacritty/tokyonight_night.toml";
    "tokyonight_storm" =
      "${nur.repos.josh.tokyonight-extras}/share/tokyonight/alacritty/tokyonight_storm.toml";
  };
  validThemes = builtins.attrNames themeImports;
  themeImport =
    assert (lib.asserts.assertOneOf "theme" theme validThemes);
    themeImports.${theme};

  shell = interactiveShell;

  configs =
    [ (writers.writeTOML "alacritty.toml" config) ]
    ++ [ (writers.writeTOML "alacritty-macos.toml" macosConfig) ]
    ++ (lib.lists.optional (theme != null) themeImport)
    ++ (lib.lists.optional enableTmux tmuxConfig);

  config = {
    terminal.shell.program = shell;

    env = {
      "SHELL" = shell;
    } // lib.attrsets.optionalAttrs (theme != null) { THEME = theme; };

    window = {
      dimensions = {
        columns = 120;
        lines = 40;
      };
      padding = {
        x = 10;
        y = 10;
      };
      resize_increments = true;
    };
  };

  macosConfig = {
    window.option_as_alt = "Both";
  };
in
stdenvNoCC.mkDerivation {
  __structuredAttrs = true;

  name = "alacritty-config";

  nativeBuildInputs = [
    yq
  ];

  inherit configs;

  buildCommand = ''
    tomlq \
      --toml-output \
      --slurp \
      'reduce .[] as $item ({}; . * $item)' \
      "''${configs[@]}" >"$out"
  '';

  meta = {
    description = "Alacritty config";
    platforms = lib.platforms.all;
  };
}
