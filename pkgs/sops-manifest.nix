{
  lib,
  stdenvNoCC,
  age,
  jq,
  nur,
  sops,
  runCommand,
}:
stdenvNoCC.mkDerivation (
  finalAttrs:
  let
    isAbsolute = path: (lib.strings.hasPrefix "/" path) || (lib.strings.hasPrefix "%r/" path);

    mkPlaceholder = name: "<SOPS:${builtins.hashString "sha256" name}:PLACEHOLDER>";

    resolvePath =
      what: path:
      if isAbsolute path then
        path
      else
        assert lib.asserts.assertMsg (
          finalAttrs.homeDirectory != null
        ) "sops-manifest: ${what} path '${path}' is relative, set homeDirectory to resolve it";
        "${finalAttrs.homeDirectory}/${path}";

    resolvedSymlinkPath = resolvePath "symlinkPath" finalAttrs.symlinkPath;

    mkSecret =
      {
        name,
        sopsFile,
        key ? name,
        format ? "json",
        mode ? "0400",
        path ? "${resolvedSymlinkPath}/${name}",
      }:
      {
        inherit
          name
          key
          sopsFile
          format
          mode
          ;
        path = resolvePath "secret '${name}'" path;
        owner = null;
        uid = 0;
        group = null;
        gid = 0;
      };

    mkTemplate =
      {
        name,
        path,
        content,
        mode ? "0400",
      }:
      {
        inherit name content mode;
        path = resolvePath "template '${name}'" path;
        file = "";
        owner = null;
        uid = 0;
        group = null;
        gid = 0;
      };

    allSecrets = map mkSecret finalAttrs.sopsSecrets;
    allTemplates = map mkTemplate finalAttrs.sopsTemplates;
  in
  {
    name = "sops-manifest.json";

    __structuredAttrs = true;

    homeDirectory = null;
    symlinkPath =
      if finalAttrs.homeDirectory == null then
        "%r/secrets"
      else
        "${finalAttrs.homeDirectory}/.config/sops-nix/secrets";
    sopsSecrets = [ ];
    sopsTemplates = [ ];

    manifest = {
      symlinkPath = resolvedSymlinkPath;
      secrets = allSecrets;
      templates = allTemplates;
      placeholderBySecretName = lib.listToAttrs (
        map (secret: lib.nameValuePair secret.name (mkPlaceholder secret.name)) allSecrets
      );
      secretsMountPoint = "%r/secrets.d";
      keepGenerations = 1;
      userMode = true;
      useTmpfs = false;
      sshKeyPaths = [ ];
      ageSshKeyPaths = [ ];
      ageKeyFile = null;
      gnupgHome = null;
      logging = {
        keyImport = true;
        secretChanges = true;
      };
    };

    nativeBuildInputs = [ jq ];

    buildCommand = ''
      jq '.manifest' "$NIX_ATTRS_JSON_FILE" >$out
      ${nur.repos.josh.sops-install-secrets}/bin/sops-install-secrets -check-mode=sopsfile $out
    '';

    passthru = {
      placeholder = mkPlaceholder;

      tests =
        let
          testdata =
            runCommand "sops-manifest-testdata"
              {
                nativeBuildInputs = [
                  age
                  sops
                ];
              }
              ''
                mkdir $out
                age-keygen -o $out/key.txt 2>/dev/null
                echo '{"FOO":"bar"}' >plain.json
                sops encrypt --age "$(age-keygen -y $out/key.txt)" \
                  --input-type json --output-type json plain.json >$out/secret.json
              '';

          testPackage = finalAttrs.finalPackage.overrideAttrs (previousAttrs: {
            homeDirectory = "/tmp/sops-manifest-test";
            sopsSecrets = previousAttrs.sopsSecrets ++ [
              {
                name = "foo";
                key = "FOO";
                sopsFile = "${testdata}/secret.json";
              }
            ];
            sopsTemplates = previousAttrs.sopsTemplates ++ [
              {
                name = "foo.conf";
                path = "foo.conf";
                content = "foo=${mkPlaceholder "foo"}";
              }
            ];
          });
        in
        {
          paths =
            runCommand "test-sops-manifest-paths"
              {
                __structuredAttrs = true;
                nativeBuildInputs = [ jq ];
                manifest = testPackage;
              }
              ''
                assertEqual() {
                  if [ "$2" != "$3" ]; then
                    echo "expected $1 to be '$3' but was '$2'" >&2
                    exit 1
                  fi
                }

                assertEqual "secret path" \
                  "$(jq -r '.secrets[0].path' "$manifest")" \
                  "/tmp/sops-manifest-test/.config/sops-nix/secrets/foo"

                assertEqual "template path" \
                  "$(jq -r '.templates[0].path' "$manifest")" \
                  "/tmp/sops-manifest-test/foo.conf"

                assertEqual "template content" \
                  "$(jq -r '.templates[0].content' "$manifest")" \
                  "foo=$(jq -r '.placeholderBySecretName.foo' "$manifest")"

                touch $out
              '';
        };
    };

    meta = {
      description = "Render a sops-install-secrets manifest";
      license = lib.licenses.mit;
      platforms = lib.platforms.unix;
    };
  }
)
