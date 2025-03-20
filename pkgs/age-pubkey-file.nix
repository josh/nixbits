{ writeText }:
(writeText "age-pubkey-file" "").overrideAttrs {
  meta = {
    description = "System age pubkey file";
    longDescription = ''
      Overloadable stub to provide default system age public key
    '';
  };
}
