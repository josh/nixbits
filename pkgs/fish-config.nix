{
  lib,
  stdenvNoCC,
  runCommand,
  symlinkJoin,
  neovim,
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
    "catppuccin_frappe" =
      "${nur.repos.josh.fish-catppuccin}/share/fish/vendor_conf.d/catppuccin_frappe.fish";
    "catppuccin_latte" =
      "${nur.repos.josh.fish-catppuccin}/share/fish/vendor_conf.d/catppuccin_latte.fish";
    "catppuccin_macchiato" =
      "${nur.repos.josh.fish-catppuccin}/share/fish/vendor_conf.d/catppuccin_macchiato.fish";
    "catppuccin_mocha" =
      "${nur.repos.josh.fish-catppuccin}/share/fish/vendor_conf.d/catppuccin_mocha.fish";
  };
in
stdenvNoCC.mkDerivation (finalAttrs: {
  name = "fish-config";

  __structuredAttrs = true;

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
    direnv hook fish | sed 's|/bin/\.direnv-wrapped|/bin/direnv|' >$out
    grep --quiet --fixed-strings '/bin/direnv"' $out
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

  defaultEditor =
    if stdenvNoCC.hostPlatform.isDarwin then
      "${nixbits.bbedit-mas}/bin/bbedit --wait --resume"
    else
      "${neovim}/bin/nvim";

  buildCommand = ''
    mkdir -p $out $out/conf.d

    if [ -n "$fishEnvVarsScript" ]; then
      echo "$fishEnvVarsScript" >>$out/conf.d/env.fish
    fi

    cat >$out/conf.d/editor.fish <<'EOF'
    if not set --query EDITOR
        set --export EDITOR "@defaultEditor@"
    end
    EOF
    substituteInPlace $out/conf.d/editor.fish \
      --replace-fail '@defaultEditor@' "$defaultEditor"

    cat >$out/conf.d/go.fish <<'EOF'
    if set --query XDG_DATA_HOME
        set --export GOPATH $XDG_DATA_HOME/go
    else
        set --export GOPATH $HOME/.local/share/go
    end
    EOF

    cat ${./fish-config.fish} >>$out/config.fish
    substituteInPlace $out/config.fish \
      --replace-fail '@out@' "$out" \
      --replace-fail '@fish-path@' "$fishPath" \
      --replace-fail '@loginShellInit@' "$loginShellInit" \
      --replace-fail '@interactiveShellInit@' "$interactiveShellInit" \
      --replace-fail '@direnv-init@' "$direnvInit"

    if [ -f "$themePath" ] && [ -n "$themeName" ]; then
      cp "$themePath" $out/conf.d/$themeName.fish
    fi
  ''
  + (lib.strings.optionalString stdenvNoCC.hostPlatform.isDarwin ''
    cat ${./fish-config-darwin.fish} >$out/conf.d/darwin.fish
    substituteInPlace $out/conf.d/darwin.fish \
      --replace-fail '@fish-history-sync@' ${nixbits.fish-history-sync}
  '');

  meta.description = "Fish shell configuration";
})
