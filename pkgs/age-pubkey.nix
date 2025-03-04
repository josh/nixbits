{ writeShellScriptBin }:
let
  script = writeShellScriptBin "age-pubkey" ''
    echo "No age pubkey configured" >&2
    exit 1
  '';
in
script
// {
  meta = script.meta // {
    description = "Print system age pubkey";
    longDescription = ''
      Overloadable stub to provide default system age public key
    '';
  };
}
