{
  symlinkJoin,
  makeWrapper,
  runCommand,
  fish,
  nixbits,
  fish-config ? nixbits.fish-config,
  theme ? null,
}:
let
  fish-config-dir =
    if theme != null then fish-config.overrideAttrs { themeName = theme; } else fish-config;
in
symlinkJoin {
  pname = "fish";
  inherit (fish) version;
  paths = [ fish ];
  nativeBuildInputs = [ makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/fish \
      --add-flags "--init-command" \
      --add-flags "'source ${fish-config-dir}/config.fish'"
  '';
  passthru.tests.themes = runCommand "test-fish-themes" { } ''
    export HOME="$PWD"
    themed="$(THEME=tokyonight_bogus ${nixbits.fish}/bin/fish -c 'echo $fish_color_command')"
    if [ -z "$themed" ]; then
      echo "expected THEME=tokyonight_bogus to set fish colors"
      return 1
    fi
    plain="$(THEME=ansi_dark ${nixbits.fish}/bin/fish -c 'echo $fish_color_command')"
    if [ -n "$plain" ]; then
      echo "expected THEME=ansi_dark to keep fish defaults but was '$plain'"
      return 1
    fi
    touch $out
  '';
  inherit (fish) meta;
}
