{
  lib,
  stdenvNoCC,
  runtimeShell,
  writeShellScript,
  writeShellScriptBin,
  runCommand,
  makeWrapper,
  lndir,
  rclone,
  restic,
  nur,
  nixbits,
}:
let
  toExePath = path: if lib.attrsets.isDerivation path then lib.meta.getExe path else path;

  restic-age-key = nur.repos.josh.restic-age-key.override {
    age = nixbits.age-with-se-tpm;
  };

  tmutil-exclude-volume =
    if stdenvNoCC.isDarwin then
      nixbits.tmutil-exclude-volume
    else
      (writeShellScriptBin "tmutil-exclude-volume" ''
        echo "error: tmutil-exclude-volume is not available on this platform" >&2
        exit 1
      '');

  restic-pre-install-hook = writeShellScript "restic-pre-install-hook" ''
    code=0

    run() {
      result=$(${runtimeShell} -c "$1" 2>&1)
      if [ $? -ne 0 ]; then
        echo "+ $1" >&2
        echo "$result" >&2
        return $?
      fi
    }

    if [ -n "$RESTIC_REPOSITORY" ] && [[ "$RESTIC_REPOSITORY" == /* ]]; then
      if [ ! -f "$RESTIC_REPOSITORY/config" ]; then
        echo "error: $RESTIC_REPOSITORY restic repository not initialized" >&2
        code=1
      fi
      if [[ "$RESTIC_REPOSITORY" == /Volumes/* ]]; then
        ${lib.getExe tmutil-exclude-volume} --dry-run "$RESTIC_REPOSITORY"
      fi
    fi

    if [ -n "$RESTIC_FROM_REPOSITORY" ] && [ "$RESTIC_FROM_REPOSITORY" != "$RESTIC_REPOSITORY" ] && [ -n "$RESTIC_FROM_REPOSITORY" ] && [[ "$RESTIC_FROM_REPOSITORY" == /* ]]; then
      if [ ! -f "$RESTIC_FROM_REPOSITORY/config" ]; then
        echo "error: $RESTIC_FROM_REPOSITORY restic repository not initialized" >&2
        code=1
      fi
    fi

    if [ -n "$RESTIC_PASSWORD_COMMAND" ]; then
      if ! run "$RESTIC_PASSWORD_COMMAND"; then
        echo "error: $RESTIC_PASSWORD_COMMAND failed" >&2
        code=1
      fi
    fi

    if [ -n "$RESTIC_FROM_PASSWORD_COMMAND" ] && [ "$RESTIC_PASSWORD_COMMAND" != "$RESTIC_FROM_PASSWORD_COMMAND" ]; then
      if ! run "$RESTIC_FROM_PASSWORD_COMMAND"; then
        echo "error: $RESTIC_FROM_PASSWORD_COMMAND failed" >&2
        code=1
      fi
    fi

    exit $code
  '';

  restic-post-install-hook = writeShellScript "restic-post-install-hook" ''
    code=0

    if [ -n "$RESTIC_REPOSITORY" ] && [[ "$RESTIC_REPOSITORY" == /Volumes/* ]]; then
      ${lib.getExe tmutil-exclude-volume} "$RESTIC_REPOSITORY"
    fi

    exit $code
  '';
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
  rcloneTaildrive = true;

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
      flag="$arg"
    done

    if [ "$1" = "age-key" ]; then
      shift
      exec ${restic-age-key}/bin/restic-age-key "$@"
    fi
  '';

  buildCommand = ''
    mkdir -p $out/bin $out/share/nix/hooks/pre-install.d $out/share/nix/hooks/post-install.d
    lndir -silent ${restic} $out
    lndir -silent ${restic-age-key} $out

    appendToVar makeWrapperArgs "--prefix" "PATH" ":" "${rclone}/bin"
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

    appendToVar makeWrapperArgs "--set-default" "RCLONE_CONFIG" ""
    if [ -n "$rcloneTaildrive" ]; then
      appendToVar makeWrapperArgs "--set" "RCLONE_CONFIG_TAILDRIVE_TYPE" "webdav"
      appendToVar makeWrapperArgs "--set" "RCLONE_CONFIG_TAILDRIVE_URL" "http://100.100.100.100:8080"
      appendToVar makeWrapperArgs "--set" "RCLONE_CONFIG_TAILDRIVE_VENDOR" "other"
    fi

    appendToVar makeWrapperArgs "--run" "$resticPreRunScript"

    rm $out/bin/restic $out/bin/restic-age-key
    makeWrapper ${restic}/bin/.restic-wrapped $out/bin/restic --inherit-argv0 "''${makeWrapperArgs[@]}"
    makeWrapper ${restic-age-key}/bin/restic-age-key $out/bin/restic-age-key "''${makeWrapperArgs[@]}"
    makeWrapper ${restic-pre-install-hook} $out/share/nix/hooks/pre-install.d/$pname "''${makeWrapperArgs[@]}"
    makeWrapper ${restic-post-install-hook} $out/share/nix/hooks/post-install.d/$pname "''${makeWrapperArgs[@]}"
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
