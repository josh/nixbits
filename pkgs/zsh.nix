{ callPackage, zsh }:
zsh.overrideAttrs (previousAttrs: {
  passthru = (previousAttrs.passthru or { }) // {
    tests.starship = callPackage ../modules/wrappers/zsh/tests/starship.nix { };
    tests.direnv = callPackage ../modules/wrappers/zsh/tests/direnv.nix { };
  };
})
