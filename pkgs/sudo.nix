{
  stdenv,
  sudo,
  nixbits,
}:
(if stdenv.hostPlatform.isDarwin then nixbits.darwin.sudo else sudo).overrideAttrs (previousAttrs: {
  passthru = (previousAttrs.passthru or { }) // {
    tests = { };
  };
})
