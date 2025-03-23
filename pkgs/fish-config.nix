{
  lib,
  runCommand,
  writeText,
  nur,
  theme ? null,
}:
let
  themes = {
    "tokyonight_day" = "${nur.repos.josh.tokyonight-extras}/share/tokyonight/fish/tokyonight_day.fish";
    "tokyonight_moon" =
      "${nur.repos.josh.tokyonight-extras}/share/tokyonight/fish/tokyonight_moon.fish";
    "tokyonight_night" =
      "${nur.repos.josh.tokyonight-extras}/share/tokyonight/fish/tokyonight_night.fish";
    "tokyonight_storm" =
      "${nur.repos.josh.tokyonight-extras}/share/tokyonight/fish/tokyonight_storm.fish";
  };

  themePath =
    if theme == null then
      null
    else
      assert (lib.asserts.assertOneOf "theme" theme (builtins.attrNames themes));
      themes.${theme};

  themeSourceCommand =
    if themePath != null then
      ''
        source '${themePath}'
      ''
    else
      "";

  config = writeText "config.fish" ''
    if test -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish'
      source '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish'
    end

    ${themeSourceCommand}

    set -g fish_greeting
  '';

  themeInstallCommand =
    if themePath != null then ''cp ${themePath} $out/conf.d/${theme}.fish'' else "";
in
runCommand "fish-config" { } ''
  mkdir -p $out $out/conf.d
  cp ${config} $out/config.fish
  ${themeInstallCommand}
''
