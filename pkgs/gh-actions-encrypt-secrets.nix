{
  lib,
  writeShellApplication,
  coreutils,
  runCommand,
  jq,
  nixbits,
}:
let
  age = nixbits.age.override {
    seSupport = true;
    tpmSupport = true;
  };

  git = nixbits.git-bot;

  script = writeShellApplication {
    name = "gh-actions-encrypt-secrets";
    runtimeInputs = [
      age
      coreutils
      git
      jq
    ];
    inheritPath = false;
    text = builtins.readFile ./gh-actions-encrypt-secrets.bash;
    meta = {
      description = "Encrypt GitHub Actions secrets using age into git repository";
      platforms = lib.platforms.all;
    };
  };
in
script.overrideAttrs (
  finalAttrs: _previousAttrs: {
    passthru.tests =
      let
        gh-actions-encrypt-secrets = finalAttrs.finalPackage;
      in
      {
        empty =
          runCommand "test-empty"
            {
              __structuredAttrs = true;
              nativeBuildInputs = [
                git
                gh-actions-encrypt-secrets
              ];
              env.SECRETS_JSON = ''{}'';
              env.AGE_RECIPIENT = "age1yavtje8vqkaglu73js0njpda8a42w94hresma43h4u8y4p95pajqnrjuly";
            }
            ''
              mkdir repo
              cd repo
              git init --initial-branch secrets

              export GITHUB_OUTPUT="$TMPDIR/result"
              gh-actions-encrypt-secrets
              [ "$(cat $GITHUB_OUTPUT)" == "committed=false" ]

              touch $out
            '';

        add =
          runCommand "test-add"
            {
              __structuredAttrs = true;
              nativeBuildInputs = [
                git
                gh-actions-encrypt-secrets
              ];
              env.SECRETS_JSON = ''{ "FOO": "bar" }'';
              env.AGE_RECIPIENT = "age1yavtje8vqkaglu73js0njpda8a42w94hresma43h4u8y4p95pajqnrjuly";
            }
            ''
              mkdir repo
              cd repo
              git init --initial-branch secrets

              export GITHUB_OUTPUT="$TMPDIR/result"
              gh-actions-encrypt-secrets
              [ "$(cat $GITHUB_OUTPUT)" == "committed=true" ]
              [ -f FOO.age ]
              [ -f FOO.hash ]

              touch $out
            '';

        add-recipients =
          runCommand "test-add-multiple"
            {
              __structuredAttrs = true;
              nativeBuildInputs = [
                git
                gh-actions-encrypt-secrets
              ];
              env.SECRETS_JSON = ''{ "FOO": "bar" }'';
              env.AGE_RECIPIENTS = ''
                age1yavtje8vqkaglu73js0njpda8a42w94hresma43h4u8y4p95pajqnrjuly
                age15590tm622uhayjqnayvzupukzh4e2t2f6g2rnx230v655z0fwv9sqn5zud
              '';
            }
            ''
              mkdir repo
              cd repo
              git init --initial-branch secrets

              export GITHUB_OUTPUT="$TMPDIR/result"
              gh-actions-encrypt-secrets
              [ "$(cat $GITHUB_OUTPUT)" == "committed=true" ]
              [ -f FOO.age ]
              [ -f FOO.hash ]

              touch $out
            '';

        skip =
          runCommand "test-skip"
            {
              __structuredAttrs = true;
              nativeBuildInputs = [
                git
                gh-actions-encrypt-secrets
              ];
              env.SECRETS_JSON = ''{ "FOO": "bar" }'';
              env.AGE_RECIPIENT = "age1yavtje8vqkaglu73js0njpda8a42w94hresma43h4u8y4p95pajqnrjuly";
            }
            ''
              mkdir repo
              cd repo
              git init --initial-branch secrets

              export GITHUB_OUTPUT="$TMPDIR/result-1"
              gh-actions-encrypt-secrets
              [ "$(cat $GITHUB_OUTPUT)" == "committed=true" ]
              [ -f FOO.age ]
              [ -f FOO.hash ]

              export GITHUB_OUTPUT="$TMPDIR/result-2"
              gh-actions-encrypt-secrets
              [ "$(cat $GITHUB_OUTPUT)" == "committed=false" ]
              [ -f FOO.age ]
              [ -f FOO.hash ]

              touch $out
            '';

        remove =
          runCommand "test-remove"
            {
              __structuredAttrs = true;
              nativeBuildInputs = [
                git
                gh-actions-encrypt-secrets
              ];
              env.AGE_RECIPIENT = "age1yavtje8vqkaglu73js0njpda8a42w94hresma43h4u8y4p95pajqnrjuly";
            }
            ''
              mkdir repo
              cd repo
              git init --initial-branch secrets

              export GITHUB_OUTPUT="$TMPDIR/result-1"
              echo '{ "FOO": "bar", "BAR": "baz" }' | gh-actions-encrypt-secrets
              [ "$(cat $GITHUB_OUTPUT)" == "committed=true" ]
              [ -f FOO.age ]
              [ -f FOO.hash ]
              [ -f BAR.age ]
              [ -f BAR.hash ]

              export GITHUB_OUTPUT="$TMPDIR/result-2"
              echo '{ "FOO": "bar" }' | gh-actions-encrypt-secrets
              [ "$(cat $GITHUB_OUTPUT)" == "committed=true" ]
              [ -f FOO.age ]
              [ -f FOO.hash ]
              [ ! -f BAR.age ]
              [ ! -f BAR.hash ]

              touch $out
            '';

      };
  }
)
