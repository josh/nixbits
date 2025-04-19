{
  lib,
  stdenvNoCC,
  makeWrapper,
  nixbits,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  __structuredAttrs = true;

  mainPrograms = [
    "nix-profile-upgrade"
    "nix-profile-up"
  ];

  name = builtins.head finalAttrs.mainPrograms;

  nativeBuildInputs = [ makeWrapper ];

  makeWrapperArgs =
    [
      "--add-flags"
      "--all"
    ]
    ++ [
      "--add-flags"
      "--accept-flake-config"
    ];

  buildCommand = ''
    mkdir -p $out/bin
    for program in "''${mainPrograms[@]}"; do
      makeWrapper ${lib.getExe nixbits.nix-profile-upgrade} $out/bin/$program "''${makeWrapperArgs[@]}"
    done
  '';

  meta = {
    description = "Upgrade nix profile";
    mainProgram = builtins.head finalAttrs.mainPrograms;
  };
})
