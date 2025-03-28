{
  lib,
  stdenvNoCC,
  writeShellScript,
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
  restic-pre-install-hook = writeShellScript "restic-pre-install-hook" ''
    code=0

    if [ -n "$RESTIC_REPOSITORY" ] && [[ "$RESTIC_REPOSITORY" == /* ]]; then
      if [ ! -f "$RESTIC_REPOSITORY/config" ]; then
        echo "error: $RESTIC_REPOSITORY restic repository not initialized" >&2
        code=1
      fi
    fi

    if [ -n "$RESTIC_FROM_REPOSITORY" ] && [ "$RESTIC_FROM_REPOSITORY" != "$RESTIC_REPOSITORY" ] && [ -n "$RESTIC_FROM_REPOSITORY" ] && [[ "$RESTIC_FROM_REPOSITORY" == /* ]]; then
      if [ ! -f "$RESTIC_FROM_REPOSITORY/config" ]; then
        echo "error: $RESTIC_FROM_REPOSITORY restic repository not initialized" >&2
        code=1
      fi
    fi

    if [ -n "$RESTIC_PASSWORD_COMMAND" ]; then
      if ! "$RESTIC_PASSWORD_COMMAND" 2>/dev/null 1>/dev/null; then
        echo "error: $RESTIC_PASSWORD_COMMAND failed" >&2
        code=1
      fi
    fi

    if [ -n "$RESTIC_FROM_PASSWORD_COMMAND" ] && [ "$RESTIC_PASSWORD_COMMAND" != "$RESTIC_FROM_PASSWORD_COMMAND" ]; then
      if ! "$RESTIC_FROM_PASSWORD_COMMAND" 2>/dev/null 1>/dev/null; then
        echo "error: $RESTIC_FROM_PASSWORD_COMMAND failed" >&2
        code=1
      fi
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

  nativeBuildInputs = [
    makeWrapper
    lndir
  ];

  makeWrapperArgs =
    [
      "--prefix"
      "PATH"
      ":"
      "${rclone}/bin"
    ]
    ++ [
      "--set-default"
      "RCLONE_CONFIG"
      ""
    ]
    ++ [
      "--set"
      "RCLONE_CONFIG_TAILDRIVE_TYPE"
      "webdav"
    ]
    ++ [
      "--set"
      "RCLONE_CONFIG_TAILDRIVE_URL"
      "http://100.100.100.100:8080"
    ]
    ++ [
      "--set"
      "RCLONE_CONFIG_TAILDRIVE_VENDOR"
      "other"
    ];

  buildCommand = ''
    mkdir -p $out $out/share/nix/hooks/pre-install.d
    lndir -silent ${restic} $out
    lndir -silent ${restic-age-key} $out

    if [ -n "$resticRepository" ]; then
      appendToVar makeWrapperArgs "--set" "RESTIC_REPOSITORY" "$resticRepository"
      appendToVar makeWrapperArgs "--unset" "RESTIC_REPOSITORY_FILE"
    else
      appendToVar makeWrapperArgs "--unset" "RESTIC_REPOSITORY"
      appendToVar makeWrapperArgs "--unset" "RESTIC_REPOSITORY_FILE"
    fi
    if [ -n "$resticPasswordCommandExe" ]; then
      appendToVar makeWrapperArgs "--set" "RESTIC_PASSWORD_COMMAND" "$resticPasswordCommandExe"
      appendToVar makeWrapperArgs "--unset" "RESTIC_PASSWORD_FILE"
    else
      appendToVar makeWrapperArgs "--unset" "RESTIC_PASSWORD_COMMAND"
      appendToVar makeWrapperArgs "--unset" "RESTIC_PASSWORD_FILE"
    fi
    if [ -n "$resticFromRepository" ]; then
      appendToVar makeWrapperArgs "--set" "RESTIC_FROM_REPOSITORY" "$resticFromRepository"
      appendToVar makeWrapperArgs "--unset" "RESTIC_FROM_REPOSITORY_FILE"
    else
      appendToVar makeWrapperArgs "--unset" "RESTIC_FROM_REPOSITORY"
      appendToVar makeWrapperArgs "--unset" "RESTIC_FROM_REPOSITORY_FILE"
    fi
    if [ -n "$resticFromPasswordCommandExe" ]; then
      appendToVar makeWrapperArgs "--set" "RESTIC_FROM_PASSWORD_COMMAND" "$resticFromPasswordCommandExe"
      appendToVar makeWrapperArgs "--unset" "RESTIC_FROM_PASSWORD_FILE"
    else
      appendToVar makeWrapperArgs "--unset" "RESTIC_FROM_PASSWORD_COMMAND"
      appendToVar makeWrapperArgs "--unset" "RESTIC_FROM_PASSWORD_FILE"
    fi
    if [ -n "$resticAgeIdentityCommandExe" ]; then
      appendToVar makeWrapperArgs "--set" "RESTIC_AGE_IDENTITY_COMMAND" "$resticAgeIdentityCommandExe"
    else
      appendToVar makeWrapperArgs "--unset" "RESTIC_AGE_IDENTITY_COMMAND"
    fi

    rm $out/bin/restic $out/bin/restic-age-key
    makeWrapper ${restic}/bin/.restic-wrapped $out/bin/restic --inherit-argv0 "''${makeWrapperArgs[@]}"
    makeWrapper ${restic-age-key}/bin/restic-age-key $out/bin/restic-age-key "''${makeWrapperArgs[@]}"
    makeWrapper ${restic-pre-install-hook} $out/share/nix/hooks/pre-install.d/$pname "''${makeWrapperArgs[@]}"
  '';

  meta = {
    inherit (restic.meta) description platforms;
    mainProgram = "restic";
  };
})
