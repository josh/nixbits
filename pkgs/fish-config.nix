{
  lib,
  runCommand,
  writeText,
  nur,
  theme ? "tokyonight_night",
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
    assert (lib.asserts.assertOneOf "theme" theme (builtins.attrNames themes));
    themes.${theme};

  config = writeText "config.fish" ''
    if test -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish'
      source '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish'
    end

    source '${themePath}'

    set -g fish_greeting
  '';
in

runCommand "fish-config" { } ''
  mkdir -p $out $out/conf.d
  cp ${config} $out/config.fish
  cp ${themePath} $out/conf.d/${theme}.fish
''
