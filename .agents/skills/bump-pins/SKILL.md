---
name: bump-pins
description: Sweep a repository for pinned external versions, check upstream for newer releases, and land each dependency bump as its own Jujutsu change and bookmark. Use when the user asks to check, refresh, or bump pinned versions across a project. Never use for the project's own release version; use jj-release instead.
---

# Bump Pinned Versions

Find stale external version pins, decide which ones should move, and create an independent change
and bookmark for each dependency. Never push, open a pull request, or change the project's own
version.

## 1. Establish a clean baseline

1. Read the repository instructions and identify its formatter and required check gate.
2. Require a Jujutsu repository. Stop before changing anything rather than initializing Jujutsu or
   falling back to plain Git.
3. Require a clean working copy. Stop and report any existing edits so they cannot be folded into a
   dependency bump.
4. Save the starting working-copy change ID. Restore it with `jj edit` on every terminal path,
   including failures.
5. Discover the Git remote and its trunk bookmark from the repository instead of assuming `origin`
   or `main`. Ask if either is ambiguous, then fetch the selected remote.

```bash
jj status
jj log -r @ --no-graph -T 'change_id'
jj bookmark list --all-remotes
jj git fetch --remote <remote>
```

Read `.github/dependabot.yml` and `renovate.json` when present before inventorying pins. Treat every
ecosystem those files cover as off-limits. For example, skip `go.mod` requirements when Dependabot
declares `gomod`, and skip `uses:` pins when it declares `github-actions`. Record every skipped
ecosystem for the final report.

## 2. Inventory pins by dependency

Search the whole repository, including hidden CI and development configuration and prose
instructions. Group every occurrence by dependency rather than by file. Move all sites for one
dependency together in one change.

| Shape                 | Example                                  | Action                                                                            |
| --------------------- | ---------------------------------------- | --------------------------------------------------------------------------------- |
| Release URL version   | `ARG LITESTREAM_VERSION=0.5.16`          | Use the nearby URL to identify the upstream repository.                           |
| Version with checksum | `HELM_VERSION` beside `HELM_SHA256`      | Update the version and recompute the checksum together.                           |
| Setup-action input    | `terraform_version: 1.13.3`              | Update the literal; when it references a matrix value, update the matrix instead. |
| CI matrix row         | `restic_version: "0.18.1" # nixos-25.11` | Treat the channel comment as policy and apply section 4.                          |
| Prose floor           | `AGENTS.md`: "Go 1.24 or newer"          | Update alongside the dependency without adding a `v` or patch component.          |
| Toolchain directive   | `go.mod`: `go 1.25.8`                    | Keep it at or below the oldest supported matrix version.                          |
| Own-version constant  | `Version = "1.2.1"`                      | Never change it; apply section 3.                                                 |
| Automated pin         | `uses: ...@sha # v7.0.1`                 | Skip it and record the automation in the report.                                  |

Ignore version-shaped values that are not dependency pins:

- Kubernetes API groups such as `apiVersion: v1`, `batch/v1`, and `networking.k8s.io/v1`;
- configuration schema versions such as Dependabot's top-level `version: 2`;
- module-path suffixes such as `/v2` in a Go module path;
- runtime interpolations such as `${{ env.IMAGE }}@sha256:${digest}`.

Report divergent pins when the same dependency appears at different versions, even if no bump is
otherwise possible.

## 3. Exclude the project's own version

Apply these tests in order:

1. Compare constants with the newest Git tag. Treat a matching version as the project's own.
2. Identify self-references. Treat a chart `appVersion` that selects an image built by this same
   repository as the project's own version; treat another owner's image as a dependency.
3. Inspect interpolated release URLs. Treat a version for a different `<owner>/<repo>` as external.

Treat a chart's `version` and `appVersion` moving together as its release convention, not as a
dependency pair for this skill.

## 4. Decide which pins should move

Check each external dependency's authoritative release source, such as its GitHub releases, vendor
release index, or registry. Resolve nixpkgs candidates as described below. Then apply these rules:

- Keep matrix rows that carry a compatibility channel or release comment. Update only a row marked
  as tracking latest. Ask before changing uncommented rows whose policy is unclear.
- Keep a toolchain floor at or below the oldest version exercised by the compatibility matrix.
- Update coupled versions and checksums together or leave both unchanged.
- Regenerate lockfiles with their owning tool, such as `go mod tidy`, `uv lock`, or
  `cargo update -p`; never edit generated lockfiles by hand.
- Report non-semver codenames or distribution tags with the current upstream release and ask the
  user to choose a successor.
- Report major-version upgrades without changing them unless the user explicitly requested majors.

Record every deliberate hold and its reason. Treat a held pin as a result rather than a failure.

### Ask which version, not just the latest

Every dependency has three candidate versions: nixpkgs stable, nixpkgs unstable, and the newest
upstream release. Query nixpkgs over the network; the repository need not contain any Nix file.

```bash
STABLE=$(git ls-remote --heads https://github.com/NixOS/nixpkgs 'refs/heads/nixos-*' |
  grep -oE 'nixos-[0-9]{2}\.[0-9]{2}$' | sort -V | tail -1)
SYS=$(nix eval --raw --impure --expr builtins.currentSystem)
VERSIONS='p: builtins.listToAttrs (map (n: { name = n; value = let r = builtins.tryEval (p.${n}.version or null); in if r.success then r.value else null; }) [ "go" "golangci-lint" "restic" ])'
for ref in "$STABLE" nixpkgs-unstable; do
  nix eval --json github:NixOS/nixpkgs/$ref#legacyPackages.$SYS --apply "$VERSIONS"
done
```

List every dependency in that one evaluation per channel; `null` means nixpkgs has no such
attribute. Find a real attribute name with `nix search github:NixOS/nixpkgs/$STABLE '^<name>$'`, or
use `search.nixos.org` where Nix is unavailable.

Bump without asking when the candidates agree. Otherwise ask once for all divergent dependencies,
recommending nixpkgs stable for compilers, runtimes, and toolchains, and upstream latest for
linters, formatters, and other tooling. Take the user's answer, and record the chosen channel in
the report.

## 5. Create one change per dependency

Branch each dependency bump independently from freshly fetched remote trunk. Never stack unrelated
bumps.

```bash
jj git fetch --remote <remote>
jj new <trunk>@<remote> -m "Bump <dependency> from <old> to <new>"
# update every site, checksum, and generated lockfile for this dependency
jj diff --stat
jj bookmark create bump-<dependency>-<new> -r @
```

- Match the repository's established message style. Otherwise use one line under 72 characters,
  with no body or `Co-authored-by` trailer.
- Use a unique, bare, descriptive bookmark. If the proposed name exists locally or remotely, choose
  a more specific name instead of reusing, moving, or deleting it.
- Inspect the full diff before creating the bookmark. Require every changed file and line to belong
  to that dependency.
- Run the repository's formatter and check gate before creating the bookmark.
- If the diff contains unrelated changes or any required check fails, do not create the bookmark.
  Restore the saved starting change and report the unbookmarked failed change without retrying with
  different flags or destructively cleaning it up.

Never push a bookmark or open a pull request. Let the user review and publish the resulting changes.

## 6. Restore and report

Restore the saved starting change before reporting one row per dependency:

| Dependency | Sites | Current | Stable / unstable / latest | Chosen | Bookmark or held | Reason |
| ---------- | ----- | ------- | -------------------------- | ------ | ---------------- | ------ |

Write `-` for a channel that does not package the dependency. Explain every
held pin, bot-managed ecosystem, ambiguous non-semver pin, unrequested major upgrade, divergent pin,
and failed change after the table. Confirm that nothing was pushed and that the
starting working-copy change was restored.

## Safety Rules

- Never push, open a pull request, or modify the remote.
- Never change the project's own version or mix it into a dependency bump.
- Never change a compatibility row identified by a channel or release comment.
- Never change an ecosystem already covered by Dependabot or Renovate.
- Never pick between diverging nixpkgs and upstream candidates without asking.
- Never hand-edit a generated lockfile.
- Never change `.github/workflows/` beyond a dependency version literal.
- Never force-push, move or delete an existing bookmark, or run `jj abandon`, `jj squash`, or
  `jj rebase` against another change.
- Restore the starting change and report after any failed step; do not retry with different flags.
