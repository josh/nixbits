{
  lib,
  pkgs,
  stdenvNoCC,
  runCommand,
  makeWrapper,
  lndir,
  age,
  rclone,
  rclone-config ? nixbits.rclone-taildrive-config,
  restic-age-key ? nur.repos.josh.restic-age-key,
  restic,
  nur,
  nixbits,
}:
let
  toExePath = path: if lib.attrsets.isDerivation path then lib.meta.getExe path else path;

  age' = if age == pkgs.age then nixbits.age else age;
  restic-age-key' = restic-age-key.override {
    age = age';
    inherit rclone;
  };
in
stdenvNoCC.mkDerivation (finalAttrs: {
  __structuredAttrs = true;

  pname = "restic-wrapper";
  inherit (restic) version;

  resticRepository = "";
  resticPasswordCommand = "${restic-age-key'}/bin/restic-age-key password";
  resticFromPasswordCommand = "${restic-age-key'}/bin/restic-age-key from-password";
  resticAgeIdentityCommand = "";
  resticAgeIdentityCommandExe = toExePath finalAttrs.resticAgeIdentityCommand;
  rcloneConfig = rclone-config;

  nativeBuildInputs = [
    lndir
    makeWrapper
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
      exec ${restic-age-key'}/bin/restic-age-key "$@"
    fi
  '';

  buildCommand = ''
    appendToVar makeWrapperArgs --add-flags "--option rclone.program=${lib.getExe rclone}"
    appendToVar makeWrapperArgs --set RESTIC_REPOSITORY "$resticRepository"
    appendToVar makeWrapperArgs --unset RESTIC_REPOSITORY_FILE
    appendToVar makeWrapperArgs --set RESTIC_PASSWORD_COMMAND "$resticPasswordCommand"
    appendToVar makeWrapperArgs --unset RESTIC_PASSWORD_FILE
    appendToVar makeWrapperArgs --set RESTIC_FROM_PASSWORD_COMMAND "$resticFromPasswordCommand"
    appendToVar makeWrapperArgs --unset RESTIC_FROM_PASSWORD_FILE
    appendToVar makeWrapperArgs --set RESTIC_AGE_IDENTITY_COMMAND "$resticAgeIdentityCommandExe"
    appendToVar makeWrapperArgs --unset RESTIC_AGE_IDENTITY_FILE
    appendToVar makeWrapperArgs --set RCLONE_CONFIG "$rcloneConfig"
    appendToVar makeWrapperArgs --run "$resticPreRunScript"

    mkdir -p $out/bin
    makeWrapper ${restic}/bin/.restic-wrapped $out/bin/$pname --inherit-argv0 "''${makeWrapperArgs[@]}"
  '';

  passthru.tests =
    let
      restic = finalAttrs.finalPackage;
    in
    {
      key-help = runCommand "test-key-help" { nativeBuildInputs = [ restic ]; } ''
        ${lib.getExe restic} key --help
        ${lib.getExe restic} age-key --help
        touch $out
      '';
    };

  meta = {
    description = "A configured restic wrapper";
    inherit (restic.meta) platforms;
    mainProgram = finalAttrs.pname;
  };
})
