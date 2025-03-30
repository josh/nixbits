{
  lib,
  stdenvNoCC,
  runCommand,
  makeWrapper,
  lndir,
  rclone,
  restic,
  nur,
  nixbits,
  taildriveSupport ? true,
}:
let
  toExePath = path: if lib.attrsets.isDerivation path then lib.meta.getExe path else path;

  age = nixbits.age.override {
    seSupport = true;
    tpmSupport = true;
  };

  restic-age-key = nur.repos.josh.restic-age-key.override {
    inherit age;
  };

  rclone' = if taildriveSupport then nixbits.rclone-taildrive else rclone;
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "restic";
  inherit (restic) version;

  __structuredAttrs = true;

  resticRepository = "";
  resticPasswordCommand = "";
  resticPasswordCommandExe = toExePath finalAttrs.resticPasswordCommand;
  resticFromRepository = "";
  resticFromPasswordCommand = "";
  resticFromPasswordCommandExe = toExePath finalAttrs.resticFromPasswordCommand;
  resticAgeIdentityCommand = "";
  resticAgeIdentityCommandExe = toExePath finalAttrs.resticAgeIdentityCommand;

  nativeBuildInputs = [
    makeWrapper
    lndir
  ];

  makeWrapperArgs = [ ];

  resticPreRunScript = ''
    flag=""
    for arg in "$@"; do
      if [ "$flag" == "--repo" ]; then
        export RESTIC_REPOSITORY="$arg"
      fi
      if [ "$flag" == "--from-repo" ]; then
        export RESTIC_FROM_REPOSITORY="$arg"
      fi
      flag="$arg"
    done

    if [ "$1" = "age-key" ]; then
      shift
      exec ${restic-age-key}/bin/restic-age-key "$@"
    fi
  '';

  resticPreInstallHook = lib.getExe (
    nixbits.restic-pre-install.override {
      inherit (finalAttrs) resticRepository resticPasswordCommand;
    }
  );

  resticPostInstallHook = lib.getExe (
    nixbits.restic-post-install.override {
      inherit (finalAttrs) resticRepository;
    }
  );

  buildCommand = ''
    mkdir -p $out/bin $out/share/nix/hooks/pre-install.d $out/share/nix/hooks/post-install.d
    lndir -silent ${restic} $out
    lndir -silent ${restic-age-key} $out

    appendToVar makeWrapperArgs "--prefix" "PATH" ":" "${rclone'}/bin"
    appendToVar makeWrapperArgs "--prefix" "PATH" ":" "${restic-age-key}/bin"

    if [ -n "$resticRepository" ]; then
      appendToVar makeWrapperArgs "--set" "RESTIC_REPOSITORY" "$resticRepository"
      appendToVar makeWrapperArgs "--unset" "RESTIC_REPOSITORY_FILE"
    fi
    if [ -n "$resticPasswordCommandExe" ]; then
      appendToVar makeWrapperArgs "--set" "RESTIC_PASSWORD_COMMAND" "$resticPasswordCommandExe"
      appendToVar makeWrapperArgs "--unset" "RESTIC_PASSWORD_FILE"
    fi
    if [ -n "$resticFromRepository" ]; then
      appendToVar makeWrapperArgs "--set" "RESTIC_FROM_REPOSITORY" "$resticFromRepository"
      appendToVar makeWrapperArgs "--unset" "RESTIC_FROM_REPOSITORY_FILE"
    fi
    if [ -n "$resticFromPasswordCommandExe" ]; then
      appendToVar makeWrapperArgs "--set" "RESTIC_FROM_PASSWORD_COMMAND" "$resticFromPasswordCommandExe"
      appendToVar makeWrapperArgs "--unset" "RESTIC_FROM_PASSWORD_FILE"
    fi
    if [ -n "$resticAgeIdentityCommandExe" ]; then
      appendToVar makeWrapperArgs "--set" "RESTIC_AGE_IDENTITY_COMMAND" "$resticAgeIdentityCommandExe"
    fi

    appendToVar makeWrapperArgs "--run" "$resticPreRunScript"

    rm $out/bin/restic $out/bin/restic-age-key
    makeWrapper ${restic}/bin/.restic-wrapped $out/bin/restic --inherit-argv0 "''${makeWrapperArgs[@]}"
    makeWrapper ${restic-age-key}/bin/restic-age-key $out/bin/restic-age-key "''${makeWrapperArgs[@]}"
    makeWrapper $resticPreInstallHook $out/share/nix/hooks/pre-install.d/$pname "''${makeWrapperArgs[@]}"
    makeWrapper $resticPostInstallHook $out/share/nix/hooks/post-install.d/$pname "''${makeWrapperArgs[@]}"
  '';

  passthru.tests =
    let
      restic = finalAttrs.finalPackage;
    in
    {
      key-help = runCommand "test-key-help" { nativeBuildInputs = [ restic ]; } ''
        restic key --help
        touch $out
      '';
      age-key-help = runCommand "test-age-key-help" { nativeBuildInputs = [ restic ]; } ''
        restic-age-key --help
        restic age-key --help
        touch $out
      '';
    };

  meta = {
    inherit (restic.meta) description platforms;
    mainProgram = "restic";
  };
})
