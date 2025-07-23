{
  lib,
  pkgs,
  stdenvNoCC,
  runCommand,
  makeWrapper,
  lndir,
  age,
  bash,
  rclone,
  rclone-config ? nixbits.rclone-taildrive-config,
  # TODO: Deprecate this alias
  aws-config ? null,
  awsConfig ? null,
  awsCredentials ? null,
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
  awsConfig = if awsConfig != null then awsConfig else aws-config;
  inherit awsCredentials;

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
    prependToVar makeWrapperArgs --add-flags "--option rclone.program=${lib.getExe rclone}"
    prependToVar makeWrapperArgs --set RESTIC_REPOSITORY "$resticRepository"
    prependToVar makeWrapperArgs --unset RESTIC_REPOSITORY_FILE
    prependToVar makeWrapperArgs --set RESTIC_PASSWORD_COMMAND "$resticPasswordCommand"
    prependToVar makeWrapperArgs --unset RESTIC_PASSWORD_FILE
    prependToVar makeWrapperArgs --set RESTIC_FROM_PASSWORD_COMMAND "$resticFromPasswordCommand"
    prependToVar makeWrapperArgs --unset RESTIC_FROM_PASSWORD_FILE
    prependToVar makeWrapperArgs --set RESTIC_AGE_IDENTITY_COMMAND "$resticAgeIdentityCommandExe"
    prependToVar makeWrapperArgs --unset RESTIC_AGE_IDENTITY_FILE

    if [ -n "$rcloneConfig" ]; then
      prependToVar makeWrapperArgs --set RCLONE_CONFIG "$rcloneConfig"
    fi
    if [ -n "$awsConfig" ]; then
      prependToVar makeWrapperArgs --set AWS_CONFIG_FILE "$awsConfig"
    fi
    if [ -n "$awsCredentials" ]; then
      prependToVar makeWrapperArgs --set AWS_SHARED_CREDENTIALS_FILE "$awsCredentials"
    fi
    if [ -n "$awsConfig" ] || [ -n "$awsCredentials" ]; then
      # rclone needs `sh` to spawn aws config credentials process
      prependToVar makeWrapperArgs --suffix PATH : "${bash}/bin"
    fi

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
