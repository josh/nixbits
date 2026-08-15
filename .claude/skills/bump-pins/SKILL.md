---
name: bump-pins
description: Sweep a repository for pinned external version constants, check upstream for newer releases, and land each dependency's bump as its own jj change and bookmark. Use only when the user asks to bump, refresh, or check pinned versions across a project. For releasing the project's own version, use jj-release instead.
---

# Bump pinned versions

Versions are pinned on purpose, for reproducibility. The cost of that is drift: nothing reminds
anyone when upstream moves. This skill finds every pin, works out which ones should move, and lands
each dependency's bump as its own change.

The hard part is judgement, not detection. Most of this file is about which pins to leave alone.

**This skill never pushes.** It creates changes and bookmarks and reports them; the user pushes what
they want. It also never touches the project's own version — that belongs to `jj-release`.

## Step 1: Preconditions and baseline

This skill requires a Jujutsu repository. If there is none, stop before changing anything — do not
initialize jj or fall back to plain git.

```bash
jj status                         # STOP if the working copy is dirty
jj log -r @ -T 'change_id'        # SAVE THIS — the starting change
jj bookmark list --all-remotes    # the remote and its trunk bookmark
jj git fetch --remote <remote>
```

- **A dirty working copy ends the run.** Uncommitted work folded into a bump commit destroys the
  atomicity the whole skill exists to provide. Report it and stop.
- **Save the starting change** and `jj edit` back to it on every exit path, including failures.
- **Resolve trunk rather than assuming `main`.** Some of these repositories have no
  `refs/remotes/origin/HEAD`, so `git symbolic-ref` fails on them.

Then read the exclusion list before inspecting anything else:

```bash
cat .github/dependabot.yml renovate.json 2>/dev/null
```

Every ecosystem declared there is **off-limits**. A `package-ecosystem: gomod` entry means `go.mod`
requires are already handled; a `github-actions` entry means `uses:` pins are. Bumping them by hand
races the bot and produces conflicting branches. Note what is covered — the report says so — and
move on.

## Step 2: Inventory every pin, grouped by dependency

**Group by dependency, not by file.** This is the organizing principle of the whole skill. A single
version usually appears in several places, and those places move in lockstep, in one change, on one
bookmark. Go pinned in both a devcontainer `ARG GO_VERSION=1.26.5` and a workflow's
`go-version: "1.26.5"` is one bump with two edits, never two bumps.

Search for the shapes below, then collapse the hits into one row per dependency.

| Shape                                          | Example                                               | Action                                                                                              |
| ---------------------------------------------- | ----------------------------------------------------- | --------------------------------------------------------------------------------------------------- |
| `ARG NAME_VERSION=x.y.z` feeding a release URL | `ARG LITESTREAM_VERSION=0.5.16`                       | Bump. The URL a few lines below names the upstream repository — the best signal available.          |
| Version paired with a checksum                 | `HELM_VERSION` next to `HELM_SHA256`                  | Bump, and recompute the checksum. See step 4.                                                       |
| Setup-action version input                     | `terraform_version: 1.13.3`, `go-version: "1.26"`     | Bump. When the value is `${{ matrix.* }}`, edit the matrix instead — the input itself is not a pin. |
| CI matrix rows                                 | `restic_version: "0.18.1"` under `# nixos-25.11`      | Usually hold. See step 4.                                                                           |
| Prose version floor                            | `AGENTS.md`: "assumes Go 1.24 or newer"               | Bump alongside the dependency. No `v`, no patch component, and the easiest kind of pin to miss.     |
| Toolchain directive                            | `go.mod`: `go 1.25.8`                                 | Bump only within the floor constraint in step 4.                                                    |
| Own-version constant                           | `Version = "1.2.1"`, `Chart.yaml` `version`           | Never touch. See step 3.                                                                            |
| Already automated                              | `uses: …@sha # v7.0.1`, `FROM alpine:3.24.1@sha256:…` | Skip, and say so in the report.                                                                     |

These match a version-shaped regex but are not versions. Recognize them rather than rediscovering
them every run:

- `apiVersion: v1`, `batch/v1`, `networking.k8s.io/v1` — Kubernetes API groups
- `version: 2` at the top of `dependabot.yml` — a schema version
- `module github.com/owner/repo/v2` in `go.mod` — a module path suffix
- `${{ env.IMAGE }}@sha256:${digest}` — a shell interpolation resolved at run time

## Step 3: Tell the project's own version from its dependencies

Bumping the project's own version here would fake a release. Three tests, in priority order:

1. **Equality with the newest tag.** `git tag --sort=-v:refname | head -1` gives `v0.4.1`; a
   constant reading `0.4.1` is the project's own. The other versions in the file will not match.
2. **Self-reference.** A chart's `appVersion` that defaults the tag for an image this same
   repository builds and pushes is the project's own version wearing a dependency's clothes. The
   same field pointing at another owner's image is a real dependency.
3. **URL owner.** A version interpolated into
   `https://github.com/<owner>/<repo>/releases/download/…` where `<owner>/<repo>` is not this
   repository is unambiguously external.

A chart's `version` and `appVersion` moving together is the release convention working as intended,
not a lockstep pair for this skill to maintain.

## Step 4: Decide what actually moves

Check upstream for each external dependency — `gh release list --repo <owner>/<repo>`, the vendor's
release index, or the registry. Then apply these, which are the reason this skill is not a script:

- **A matrix row carrying a channel or release comment is a policy, not drift.** Rows commented
  `# nixos-25.11` or `# debian-bookworm` deliberately hold an older version so compatibility with
  that channel stays tested. Bumping one silently deletes a test. Only the row marked as tracking
  latest follows upstream; the rest move when their channel moves, and the comment moves with them.
  When rows carry no comments, ask before touching any of them.
- **A toolchain directive is a floor, not a pin.** `go.mod`'s `go` line has to stay at or below the
  oldest version in the matrix. Raising it above the oldest row breaks that row.
- **Coupled values move together or not at all.** A version bumped without its recomputed checksum
  fails CI at the verification step, and the failure looks like a bad download. Fetch the new
  artifact, compute the digest, and change both lines in the same edit.
- **Generated files are regenerated, never hand-edited.** Bumping a manifest that has a lockfile
  means re-running the tool that owns it — `go mod tidy`, `uv lock`, `cargo update -p`. A repository
  that checks the lockfile in CI will reject the hand-edited version.
- **Non-semver pins need a judgement call.** A release codename or a distribution tag has no
  successor a regex can compute. Report it with what the current release is and let the user decide.
- **A major-version jump is report-only** unless the user asked for majors. Say what the new major
  is and what it would take.

### Latest is not the only candidate

A version in a nixpkgs channel was already built against everything else in that channel; a tag cut
yesterday has been integrated with nothing. So every dependency has three candidates — nixpkgs
stable, nixpkgs unstable, upstream latest. nixpkgs is queried over the network, so none of this
needs a flake or any Nix file in the repository.

```bash
STABLE=$(git ls-remote --heads https://github.com/NixOS/nixpkgs 'refs/heads/nixos-*' |
  grep -oE 'nixos-[0-9]{2}\.[0-9]{2}$' | sort -V | tail -1)
SYS=$(nix eval --raw --impure --expr builtins.currentSystem)
VERSIONS='p: builtins.listToAttrs (map (n: { name = n; value = let r = builtins.tryEval (p.${n}.version or null); in if r.success then r.value else null; }) [ "go" "golangci-lint" "restic" ])'
for ref in "$STABLE" nixpkgs-unstable; do
  nix eval --json github:NixOS/nixpkgs/$ref#legacyPackages.$SYS --apply "$VERSIONS"
done
```

Put every dependency in that one list — a batched eval is under a second, while `nix search`
evaluates the whole package set and costs ~20s. Use search only when a name comes back `null`,
anchored (`nix search github:NixOS/nixpkgs/$STABLE '^ripgrep$'`), since the attribute is not always
the tool name. `search.nixos.org` shows the same versions where Nix is unavailable.

**Agreeing candidates need no question** — bump and move on. **Diverging ones do**, and the split
goes by kind of dependency:

- **Toolchains follow stable.** A compiler ahead of the channel is built against what nothing else
  in that channel is.
- **Linters and formatters follow latest.** New diagnostics are the whole point.

Recommend on that basis, ask once for all divergent dependencies at the same time, and take
whatever the user picks. Record the chosen channel in the report.

Divergent pins are a finding worth reporting even when nothing is bumpable: the same dependency
pinned to two different versions in two files is drift that no upstream check will surface.

If a pin is deliberate and should stay, say so with the reason. Holding a pin is a result, not a
failure to act.

## Step 5: One change per dependency

Every change branches from freshly fetched trunk. **Never stack them** — each has to be pushable and
mergeable on its own.

```bash
jj git fetch --remote <remote>
jj new <trunk>@<remote> -m "Bump <dep> from <old> to <new>"
# edit every site for this dependency, recompute coupled checksums, regenerate lockfiles
jj diff --stat
jj bookmark create bump-<dep>-<new> -r @
```

- **Message**: read the shape off the repository's own history first; `Bump <dep> from <old> to
<new>` is the usual form. One line, under 72 characters, no body, no `Co-authored-by`.
- **Bookmark**: a bare descriptive slug, no prefix. If the name already exists locally or on the
  remote, pick a more specific one; never reuse it.
- **Check the diff.** Only that dependency's sites should have moved. If anything else appears,
  abandon the edit rather than committing it.
- Run whatever check gate the repository has, and the formatter, before moving to the next
  dependency.

**Do not push, and do not open a pull request.** Report the bookmarks and stop.

## Step 6: Report and restore

Restore the saved starting change, then report one row per dependency:

| Dependency | Sites | Current | Stable / unstable / latest | Chosen | Bookmark or held | Reason |
| ---------- | ----- | ------- | -------------------------- | ------ | ---------------- | ------ |

Write `-` for a channel that does not package it. After the table, explain every held pin, every ecosystem skipped because automation already covers
it, every non-semver or major-version pin left for the user, and any divergent pin found along the
way. Confirm that nothing was pushed and that the starting change was restored.

## Safety rules

- **Never push.** No `jj git push`, no `gh pr create`. The user pushes and merges.
- Never bump the project's own version, and never mix an own-version bump into a dependency change.
- Never bump a matrix row that a comment marks as a compatibility floor.
- Never bump a version in an ecosystem that `dependabot.yml` or `renovate.json` already declares.
- Never choose between diverging nixpkgs and upstream versions unilaterally — ask.
- Never hand-edit a generated lockfile — regenerate it with the tool that owns it.
- Never change anything in `.github/workflows/` beyond the version literal itself.
- Never force-push, move or delete a pre-existing bookmark, or run `jj abandon`, `jj squash`, or
  `jj rebase` against another change.
- If a step fails, restore the starting change and report — do not retry with different flags.
