{
  lib,
  stdenvNoCC,
  runCommand,
  symlinkJoin,
  nur,
  nixbits,
}:
let
  inherit (nixbits) direnv;

  availableThemes = {
    "tokyonight_day" = "${nur.repos.josh.tokyonight-extras}/share/tokyonight/fish/tokyonight_day.fish";
    "tokyonight_moon" =
      "${nur.repos.josh.tokyonight-extras}/share/tokyonight/fish/tokyonight_moon.fish";
    "tokyonight_night" =
      "${nur.repos.josh.tokyonight-extras}/share/tokyonight/fish/tokyonight_night.fish";
    "tokyonight_storm" =
      "${nur.repos.josh.tokyonight-extras}/share/tokyonight/fish/tokyonight_storm.fish";
  };
in
stdenvNoCC.mkDerivation (finalAttrs: {
  __structuredAttrs = true;

  name = "fish-config";

  fishPath = symlinkJoin {
    name = "fish-path";
    paths = [
      direnv
    ];
  };

  fishEnvVars = { };
  extraFishEnvVars = lib.attrsets.optionalAttrs (finalAttrs.themeName != null) {
    THEME = finalAttrs.themeName;
  };

  fishEnvVarsScript = builtins.concatStringsSep "\n" (
    lib.attrsets.mapAttrsToList (name: value: ''
      set --export ${builtins.toString name} "${builtins.toString value}"
    '') (finalAttrs.fishEnvVars // finalAttrs.extraFishEnvVars)
  );

  direnvInit = runCommand "direnv-init.fish" { nativeBuildInputs = [ direnv ]; } ''
    direnv hook fish >$out
  '';

  themeName = null;

  themePath =
    if finalAttrs.themeName == null then
      null
    else
      assert (lib.asserts.assertOneOf "theme" finalAttrs.themeName (builtins.attrNames availableThemes));
      availableThemes.${finalAttrs.themeName};

  interactiveShellInit = "";
  loginShellInit = "";

  buildCommand = ''
    mkdir -p $out $out/conf.d

    if [ -n "$fishEnvVarsScript" ]; then
      echo "$fishEnvVarsScript" >>$out/conf.d/env.fish
    fi

    cat ${./fish-config.fish} >>$out/config.fish
    substituteInPlace $out/config.fish \
      --replace-warn '@out@' "$out" \
      --replace-fail '@fish-path@' "$fishPath" \
      --replace-fail '@loginShellInit@' "$loginShellInit" \
      --replace-fail '@interactiveShellInit@' "$interactiveShellInit" \
      --replace-fail '@direnv-init@' "$direnvInit"

    if [ -f "$themePath" ] && [ -n "$themeName" ]; then
      cp $themePath $out/conf.d/$themeName.fish
    fi
  ''
  + (lib.strings.optionalString stdenvNoCC.isDarwin ''
    cat ${./fish-config-darwin.fish} >$out/conf.d/darwin.fish
    substituteInPlace $out/conf.d/darwin.fish \
      --replace-fail '@fish-history-sync@' ${nixbits.fish-history-sync}
  '');
})
