{
  lib,
  stdenvNoCC,
  writers,
  yq,
  nur,
  nixbits,
  interactiveShell ? nixbits.fish,
  theme ? "tokyonight_moon",
  enableTmux ? true,
}:
let
  tmuxConfig = nixbits.alacritty-tmux-config.override { inherit theme; };

  themeImports = {
    "catppuccin_frappe" = "${nur.repos.josh.alacritty-catppuccin}/catppuccin-frappe.toml";
    "catppuccin_latte" = "${nur.repos.josh.alacritty-catppuccin}/catppuccin-latte.toml";
    "catppuccin_macchiato" = "${nur.repos.josh.alacritty-catppuccin}/catppuccin-macchiato.toml";
    "catppuccin_mocha" = "${nur.repos.josh.alacritty-catppuccin}/catppuccin-mocha.toml";
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

  shell = lib.getExe interactiveShell;

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
