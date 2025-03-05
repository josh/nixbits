{ writeText }:
let
  file = writeText "age-pubkey-file" "";
in
file
// {
  meta = file.meta // {
    description = "System age pubkey file";
    longDescription = ''
      Overloadable stub to provide default system age public key
    '';
  };
}
