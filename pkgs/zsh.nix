{ callPackage, zsh }:
zsh.overrideAttrs (previousAttrs: {
  passthru = (previousAttrs.passthru or { }) // {
    tests.completion = callPackage ../modules/wrappers/zsh/tests/completion.nix { };
    tests.starship = callPackage ../modules/wrappers/zsh/tests/starship.nix { };
    tests.direnv = callPackage ../modules/wrappers/zsh/tests/direnv.nix { };
  };
})
