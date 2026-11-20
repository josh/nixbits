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
    tests.${if stdenv.hostPlatform.isDarwin then "prefer-system-log" else null} =
      callPackage ../modules/wrappers/zsh/tests/prefer-system-log.nix
        { };
    tests.${if stdenv.hostPlatform.isDarwin then "ssh-keychain-provider" else null} =
      callPackage ../modules/wrappers/zsh/tests/ssh-keychain-provider.nix
        { };
    tests.interactive-profile = callPackage ../modules/wrappers/zsh/tests/interactive-profile.nix { };
    tests.starship = callPackage ../modules/wrappers/zsh/tests/starship.nix { };
    tests.direnv = callPackage ../modules/wrappers/zsh/tests/direnv.nix { };
  };
})
