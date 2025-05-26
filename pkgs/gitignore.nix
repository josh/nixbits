{
  lib,
  stdenvNoCC,
  runCommand,
  git,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  name = "gitignore";
  __structuredAttrs = true;

  patterns =
    [
      # direnv
      ".envrc"
      ".direnv/"

      # Nix
      "result"
      "result-*"

      # Claude code
      "**/.claude/settings.local.json"
    ]
    ++ (lib.lists.optionals stdenvNoCC.hostPlatform.isDarwin [
      ".DS_Store"
    ]);

  buildCommand = ''
    for pattern in "''${patterns[@]}"; do
      echo "$pattern" >>"$out"
    done
  '';

  passthru.tests =
    let
      gitignore = finalAttrs.finalPackage;
    in
    {
      check-ignore =
        runCommand "test-git-check-ignore"
          {
            __structuredAttrs = true;
            nativeBuildInputs = [ git ];
            includedExamples = [
              "README.md"
            ];
            excludedExamples = [
              ".envrc"
              "result"
              "result-man"
              ".claude/settings.local.json"
            ];
          }
          ''
            git init --initial-branch main
            cat ${gitignore} >.gitignore

            errors=0

            for path in "''${includedExamples[@]}"; do
              echo "+ git check-ignore $path"
              if git check-ignore "$path"; then
                echo "expected $path to be included but was excluded"
                errors=$((errors + 1))
              fi
            done

            for path in "''${excludedExamples[@]}"; do
              echo "+ git check-ignore $path"
              if ! git check-ignore "$path"; then
                echo "expected $path to be excluded but was not"
                errors=$((errors + 1))
              fi
            done

            [ $errors -eq 0 ]
            touch $out
          '';
    };
})
