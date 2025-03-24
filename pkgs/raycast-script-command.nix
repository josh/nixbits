{
  lib,
  stdenvNoCC,
  runtimeShell,
  hello,
}:
let
  requiredParameters = [
    "schemaVersion"
    "title"
    "mode"
    "command"
  ];

  formatLine = name: value: "# @raycast.${name} ${builtins.toString value}";

  formatOptionalParameters =
    s:
    builtins.concatStringsSep "\n" (
      lib.attrsets.mapAttrsToList (name: value: formatLine name value) (
        builtins.removeAttrs s requiredParameters
      )
    );
in
stdenvNoCC.mkDerivation (finalAttrs: {
  __structuredAttrs = true;

  name = "raycast-script-command";

  raycast = {
    schemaVersion = 1;
    title = "Hello";
    mode = "fullOutput";
    command = hello;
  };

  scriptText = ''
    #!${runtimeShell}

    # Required parameters:
    ${formatLine "schemaVersion" (
      if builtins.hasAttr "schemaVersion" finalAttrs.raycast then finalAttrs.raycast.schemaVersion else 1
    )}
    ${formatLine "title" finalAttrs.raycast.title}
    ${formatLine "mode" finalAttrs.raycast.mode}

    # Optional parameters:
    ${formatOptionalParameters finalAttrs.raycast}

    exec "${lib.getExe finalAttrs.raycast.command}"
  '';

  buildCommand = ''
    mkdir $out
    echo "$scriptText" >"$out/$name.sh"
    chmod +x "$out/$name.sh"
  '';

  meta = {
    description = "Raycast Script Command Template";
    platforms = lib.platforms.darwin;
  };
})
