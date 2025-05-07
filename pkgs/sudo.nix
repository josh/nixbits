{
  stdenv,
  sudo,
  darwin,
}:
(if stdenv.hostPlatform.isDarwin then darwin.sudo else sudo).overrideAttrs {
  passthru.tests = { };
}
