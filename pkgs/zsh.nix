{ callPackage, zsh }:
zsh.overrideAttrs (previousAttrs: {
  passthru = (previousAttrs.passthru or { }) // {
    tests.direnv = callPackage ../modules/wrappers/zsh/tests/direnv.nix { };
  };
})
