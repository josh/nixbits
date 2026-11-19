{
  callPackage,
  stdenv,
  zsh,
}:
zsh.overrideAttrs (previousAttrs: {
  passthru = (previousAttrs.passthru or { }) // {
    tests.${if stdenv.hostPlatform.isDarwin then "apple-terminal" else null} =
      callPackage ../modules/wrappers/zsh/tests/apple-terminal.nix
        { };
    tests.${if stdenv.hostPlatform.isDarwin then "combining-chars" else null} =
      callPackage ../modules/wrappers/zsh/tests/combining-chars.nix
        { };
    tests.completion = callPackage ../modules/wrappers/zsh/tests/completion.nix { };
    tests.starship = callPackage ../modules/wrappers/zsh/tests/starship.nix { };
    tests.direnv = callPackage ../modules/wrappers/zsh/tests/direnv.nix { };
  };
})
