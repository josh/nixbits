{
  lib,
  stdenvNoCC,
  runtimeShell,
  runCommand,
  attic-server,
  openssl,
  shellcheck-minimal,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "atticadm-make-token";
  inherit (attic-server) version;

  __structuredAttrs = true;

  text = ''
    #!${runtimeShell}
    set -o errexit

    if [ -n "$ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64" ]; then
      :
    elif [ -f "$ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64_FILE" ]; then
      ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64="$(<"$ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64_FILE")"
      export ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64
    elif [ -f "$CREDENTIALS_DIRECTORY/attic-server-token-rs256-secret-base64" ]; then
      ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64="$(<"$CREDENTIALS_DIRECTORY/attic-server-token-rs256-secret-base64")"
      export ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64
    fi

    exec ${attic-server}/bin/atticadm make-token --config ${./atticadm-make-token-config.toml} "$@"
  '';

  buildCommand = ''
    target="$out/bin/atticadm-make-token"
    mkdir -p $out/bin
    echo -n "$text" >"$target"
    chmod +x "$target"

    runHook preCheck
    $SHELL -n "$target"
    ${lib.meta.getExe shellcheck-minimal} "$target"
    runHook postCheck
  '';

  passthru.tests =
    let
      atticadm-make-token = finalAttrs.finalPackage;
      nativeBuildInputs = [
        atticadm-make-token
        openssl
      ];
    in
    {
      env-str = runCommand "env-str" { inherit nativeBuildInputs; } ''
        export ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64=$(openssl genrsa -traditional 4096 | base64 -w0)
        atticadm-make-token --sub "alice" --validity "2y" --pull "dev-*" --push "dev-*" --pull "prod"
        touch $out
      '';

      env-file = runCommand "env-file" { inherit nativeBuildInputs; } ''
        export ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64_FILE=$(mktemp -t attic-server-token-rs256-secret-base64.XXXXXX)
        openssl genrsa -traditional 4096 | base64 -w0 >"$ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64_FILE"
        atticadm-make-token --sub "alice" --validity "2y" --pull "dev-*" --push "dev-*" --pull "prod"
        touch $out
      '';

      credentials-directory = runCommand "credentials-directory" { inherit nativeBuildInputs; } ''
        export CREDENTIALS_DIRECTORY=$(mktemp -d)
        openssl genrsa -traditional 4096 | base64 -w0 >"$CREDENTIALS_DIRECTORY/attic-server-token-rs256-secret-base64"
        atticadm-make-token --sub "alice" --validity "2y" --pull "dev-*" --push "dev-*" --pull "prod"
        touch $out
      '';
    };

  meta = {
    description = "Wrapper around atticadm make-token";
    inherit (attic-server.meta) platforms;
    mainProgram = "atticadm-make-token";
  };
})
