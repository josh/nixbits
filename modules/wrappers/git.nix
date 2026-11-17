{
  config,
  lib,
  pkgs,
  wlib,
  ...
}:
let
  inherit (pkgs) nixbits;
  inherit (nixbits) gh;
in
{
  imports = [ wlib.wrapperModules.git ];

  package = pkgs.symlinkJoin {
    pname = "git";
    inherit (pkgs.git) version meta;
    paths = [
      pkgs.git
      nixbits.git-branch-prune
      nixbits.git-fetch-dir
    ];
  };

  settings = {
    user = {
      name = "Joshua Peek";
      email = "josh@users.noreply.github.com";
    };

    alias = {
      b = "branch";
      ba = "branch --all";
      ca = "commit --all";
      ci = "commit";
      co = "checkout";
      ct = "checkout --track";
      patch = "!git --no-pager diff --no-color";
      st = "status --short --branch";
      up = "pull";
    };

    # Improve listing branches
    # <https://blog.gitbutler.com/how-git-core-devs-configure-git/#listing-branches>
    column.ui = "auto";
    branch.sort = "-committerdate";

    # Improve listing tags
    # <https://blog.gitbutler.com/how-git-core-devs-configure-git/#listing-tags>
    tag.sort = "version:refname";

    # Set default branch
    # <https://blog.gitbutler.com/how-git-core-devs-configure-git/#default-branch>
    init.defaultBranch = "main";

    # Better diff
    # <https://blog.gitbutler.com/how-git-core-devs-configure-git/#better-diff>
    diff = {
      algorithm = "histogram";
      colorMoved = "plain";
      mnemonicPrefix = true;
      renames = true;
    };

    # Better pushing
    # <https://blog.gitbutler.com/how-git-core-devs-configure-git/#better-pushing>
    push = {
      default = "simple"; # (default since 2.0)
      autoSetupRemote = true;
      followTags = true;
    };

    # Better pulling
    # <https://blog.gitbutler.com/how-git-core-devs-configure-git/#better-pulling>
    pull = {
      rebase = true;
    };

    # Better fetching
    # <https://blog.gitbutler.com/how-git-core-devs-configure-git/#better-fetching>
    fetch = {
      prune = true;
      pruneTags = true;
      all = true;
    };

    # Autocorrect prompting
    # <https://blog.gitbutler.com/how-git-core-devs-configure-git/#autocorrect-prompting>
    help.autocorrect = "prompt";

    # Commit with diffs
    # <https://blog.gitbutler.com/how-git-core-devs-configure-git/#commit-with-diffs>
    commit.verbose = true;

    # Reuse recorded resolutions
    # <https://blog.gitbutler.com/how-git-core-devs-configure-git/#reuse-recorded-resolutions>
    rerere = {
      enabled = true;
      autoupdate = true;
    };

    # Global ignore file
    # <https://blog.gitbutler.com/how-git-core-devs-configure-git/#global-ignore-file>
    core.excludesFile = "${nixbits.gitignore}";

    # Slightly nicer rebase
    # <https://blog.gitbutler.com/how-git-core-devs-configure-git/#slightly-nicer-rebase>
    rebase = {
      autoSquash = true;
      autoStash = true;
      updateRefs = true;
    };

    # Better merge conflicts
    # <https://blog.gitbutler.com/how-git-core-devs-configure-git/#better-merge-conflicts>
    # merge.conflictstyle = "zdiff3";

    # The empty helper resets the inherited list, see gitcredentials(7)
    credential = {
      "https://github.com".helper = [
        ""
        "${lib.getExe gh} auth git-credential"
      ];
      "https://gist.github.com".helper = [
        ""
        "${lib.getExe gh} auth git-credential"
      ];
    }
    // (lib.attrsets.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
      helper = "osxkeychain";
    });

    # diff-so-fancy
    core.pager = "${lib.getExe pkgs.diff-so-fancy} | ${lib.getExe pkgs.less} --tabs=4 -RF";
    interactive.diffFilter = "${lib.getExe pkgs.diff-so-fancy} --patch";
    diff-so-fancy.markEmptyLines = false;
  };

  passthru.tests =
    let
      git = config.wrapper;
    in
    {
      config-override =
        let
          customConfig = pkgs.writeText "custom-git-config" ''
            [user]
              name = Custom Git User
              email = custom@example.com
            [credential "https://git.example.com"]
                helper =
                helper = custom-helper
          '';
          custom = pkgs.wlibEvalPackage [
            ./git.nix
            { configFile.path = customConfig; }
          ];
        in
        pkgs.runCommand "test-git-config-override" { } ''
          export HOME="$TMPDIR/home"
          mkdir -p "$HOME"
          export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/ignored/git-config
          test "$(${custom}/bin/git config get user.name)" = "Custom Git User"
          test "$(${custom}/bin/git config get user.email)" = custom@example.com
          test "$(${custom}/bin/git config get --url=https://git.example.com credential.helper)" = custom-helper
          test "$(${custom}/bin/git config get --show-origin user.name)" = "$(printf 'file:%s\t%s' ${customConfig} 'Custom Git User')"
          touch "$out"
        '';

      version = pkgs.testers.testVersion {
        package = git;
        command = "git version";
        inherit (git) version;
      };

      author = pkgs.runCommand "test-git-author" { nativeBuildInputs = [ git ]; } ''
        expected="Joshua Peek"
        actual="$(git config get user.name)"
        if [[ "$actual" != "$expected" ]]; then
          echo "expected, '$expected' but was '$actual'"
          return 1
        fi
        touch $out
      '';

      default-branch = pkgs.runCommand "test-git-default-branch" { nativeBuildInputs = [ git ]; } ''
        git init
        if [[ "$(git branch --show-current)" != "main" ]]; then
          echo "expected, 'main' but was '$(git branch --show-current)'"
          return 1
        fi
        touch $out
      '';

      ignore = pkgs.runCommand "test-git-ignore" { nativeBuildInputs = [ git ]; } ''
        git init
        touch README.md
        mkdir .claude
        touch .claude/settings.local.json
        if git check-ignore README.md; then
          echo "expected README.md to not be ignored"
          return 1
        fi
        if ! git check-ignore .claude/settings.local.json; then
          echo "expected .claude/settings.local.json to be ignored"
          return 1
        fi
        touch $out
      '';

      credential-helpers =
        pkgs.runCommand "test-git-credential-helpers" { nativeBuildInputs = [ git ]; }
          ''
            expected="${lib.getExe nixbits.gh} auth git-credential"
            for url in https://github.com https://gist.github.com; do
              actual="$(git config get --url=$url credential.helper)"
              if [[ "$actual" != "$expected" ]]; then
                echo "expected, '$expected' but was '$actual' for $url"
                return 1
              fi
            done
            touch $out
          '';

      bundled-helpers =
        pkgs.runCommand "test-git-bundled-helpers" { nativeBuildInputs = [ config.wrapper ]; }
          ''
            export HOME="$TMPDIR/home"
            mkdir -p "$HOME"
            export GIT_CONFIG_NOSYSTEM=1
            unset GIT_CONFIG_GLOBAL
            test -x ${config.wrapper}/bin/git-branch-prune
            test -x ${config.wrapper}/bin/git-fetch-dir
            git init -b main repo
            cd repo
            git commit --allow-empty -m initial
            git branch merged
            git branch-prune
            if git show-ref --verify --quiet refs/heads/merged; then
              echo "bundled branch-prune did not delete the merged branch"
              exit 1
            fi
            cd ..
            git init --bare remote.git
            git -C repo remote add origin "$PWD/remote.git"
            git -C repo push origin main
            git -C repo update-ref -d refs/remotes/origin/main
            git fetch-dir "$PWD/repo"
            test "$(git -C repo rev-parse origin/main)" = "$(git -C repo rev-parse main)"
            touch "$out"
          '';
    };
}
