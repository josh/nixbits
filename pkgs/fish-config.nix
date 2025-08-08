{
  lib,
  stdenvNoCC,
  runCommand,
  writeText,
  symlinkJoin,
  nur,
  nixbits,
  theme ? null,
}:
let
  inherit (nixbits) direnv;

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

  direnv-init = runCommand "direnv-init" { nativeBuildInputs = [ direnv ]; } ''
    direnv hook fish >$out
  '';

  path = symlinkJoin {
    name = "fish-path";
    paths = [
      direnv
    ];
  };

  config = writeText "config.fish" (
    ''
      if test -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish'
        source '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish'
      end

      ${themeSourceCommand}

      set -g fish_greeting

      set --export PATH $PATH ${path}/bin

      status is-login; and begin
        # Login shell initialization
      end

      status is-interactive; and begin
        # Interactive shell initialization
        source ${direnv-init}
      end
    ''
    + (lib.strings.optionalString stdenvNoCC.isDarwin ''

      if begin
          status --is-interactive
          and status --is-login
          and test -d "$HOME/Library/Mobile Documents/com~apple~CloudDocs/Terminal/history"
        end
        function on_exit --on-event fish_exit
          echo "...syncing history" 1>&2
          ${lib.getExe nixbits.fish-history-sync}
        end
      end
    '')
  );

  themeInstallCommand =
    if themePath != null then ''cp ${themePath} $out/conf.d/${theme}.fish'' else "";
in
runCommand "fish-config" { } ''
  mkdir -p $out $out/conf.d
  cp ${config} $out/config.fish
  ${themeInstallCommand}
''
