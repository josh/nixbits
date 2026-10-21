{
  wlibEvalPackage,
  nixbits,
  fish-config ? nixbits.fish-config,
  theme ? null,
}:
wlibEvalPackage [
  {
    fishConfig =
      if theme != null then fish-config.overrideAttrs { themeName = theme; } else fish-config;
  }
  ../modules/fish-wrapper.nix
]
