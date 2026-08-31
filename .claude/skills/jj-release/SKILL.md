---
name: jj-release
description: Cut and push a tagged release in a jj repository colocated with git. Use only when the user names a version to release, cut, or tag (e.g. "release 0.7.1", "ship a patch version"). For committing, describing, or pushing ordinary work — including bumping a version string without tagging — use jj-describe instead.
allowed-tools: Bash(git log:*), Bash(git show:*), Bash(git for-each-ref:*), Bash(git ls-remote:*), Bash(jj log:*), Bash(jj diff:*), Bash(jj status:*), Bash(jj describe:*), Bash(jj bookmark:*), Bash(jj tag:*), Bash(jj git push:*), Bash(uv lock:*), Read, Edit
---

# Release workflow (jj colocated with git)

**Confirm before running anything.** This skill gets invoked when `jj-describe` was meant. State the
package, version, and trunk bookmark you are about to release and wait for a yes. No version number
in the request means it was almost certainly a mistake — ask, don't infer one.

**jj owns the whole release** — describe, bookmark, tag, push. `jj tag set` creates the tag and
`jj git push --bookmark <trunk> --tag v<version>` publishes both refs in one command. Git is kept
here for reading history only; it writes nothing, which is why `git tag` and `git push` are absent
from `allowed-tools`.

## Step 1: Find the last release tag and read it

Nothing about the release shape is assumed — read it off the last one.

```bash
git for-each-ref --sort=-v:refname --format='%(refname:short)' refs/tags | head -3
git show <previous-tag>                     # commit subject AND the files carrying the version
git log <previous-tag>..<trunk> --oneline   # what is actually unreleased
```

**The sort has to be version-aware.** A lexicographic sort ranks `v0.9.0` above `v0.10.0`, which
reads the wrong release as the latest and bumps from the wrong base. `-v:refname` sorts by version.
Check any substitute against that case before trusting it.

Two things come out of `git show`, and both matter:

- **The file set.** Exactly which files the last release touched, and which line in each carries
  the version. Bump those files and nothing else. Watch for a file carrying the version in more
  than one place, where every occurrence must move in lockstep, and preserve quoting exactly.
- **The commit subject.** Confirmation that this repository follows the convention below, not a
  format to reverse-engineer from scratch. If it deviates, follow the repository.

If the unreleased changes warrant a different bump level than the user asked for, say so in a
sentence, then proceed with what they asked. If there is no prior tag, ask for the version-file set
rather than guessing at it.

## The two formats

Both are fixed rules, not per-repository discoveries. They differ, deliberately:

| Artifact       | Format                              | Example     |
| -------------- | ----------------------------------- | ----------- |
| Commit subject | `<package name> <version>` — no `v` | `foo 1.4.0` |
| Git tag        | `v<version>` — always a `v`         | `v1.4.0`    |

The subject is one line and nothing else: no prefix, no body, no `Co-authored-by`, no summary of
what changed. The package name is the repository's own name for itself — the module path, chart
name, or binary name the previous release used.

The subject omitting the `v` while the tag carries it is the convention working as intended, not a
discrepancy to fix.

## Step 2: Bump and verify

Edit the files, then confirm the diff matches the previous release's shape — same files, same line
count:

```bash
jj diff --stat
```

Stop if anything else moved. If the working copy already had unrelated changes, ask before folding
them into a release commit.

**`pyproject.toml` and `uv.lock` move in lockstep.** The lockfile pins the project's own version, so
bumping `pyproject.toml` leaves it stale. Re-lock before the diff check:

```bash
uv lock
```

`uv.lock` ships in every release that bumped a version in `pyproject.toml` — this one is a rule, not
something to read off the previous release. A release that forgot the lockfile looks exactly like a
release that never needed one, so copying its file set repeats the miss. The exception is a dynamic
version (`hatch-vcs`, `setuptools-scm`), where `pyproject.toml` carries no version string to bump.
If `uv lock` rewrites anything beyond the project's own version entry, that is pre-existing drift —
say so before committing.

## Step 3: Commit, tag, and push

Resolve the trunk bookmark rather than assuming `main`:

```bash
jj describe --message "<package name> <version>"
jj bookmark set <trunk> -r @
jj tag set v<version> -r <trunk>
jj git push --bookmark <trunk> --tag v<version>
```

The order is load-bearing: `jj tag set` reads `<trunk>`, so moving the bookmark first is what puts
the tag on the release commit instead of the one before it. There is no SHA to copy — the revset
resolves it, and jj rewriting commit ids afterwards cannot strand the tag.

**One push, not two.** `jj git push --tag v<version>` on its own publishes the release commit under
the tag while leaving `<trunk>` pointing at its parent — a released version that is not on the
branch. Name both refs in the same command.

**Name the exact tag.** `--tag` matches glob patterns and `--all` pushes every bookmark and tag.
Neither belongs in a release.

If `jj tag set` reports `Refusing to move tag`, that version is already released. Stop and ask —
never pass `--allow-move`.

A `Bypassed rule violations` line means an admin bypass carried the push past a
required-status-checks ruleset — that is success, not a warning. A hard rejection means the release
needs a PR instead; stop and ask.

## Step 4: Confirm

```bash
git ls-remote origin refs/heads/<trunk> refs/tags/v<version>
```

Both should print the same SHA. Report that plainly. **The pushed tag is the whole release** — stop
here.

`git ls-remote` asks the remote; `jj tag list -a` only shows jj's local record of what it last
pushed or fetched. Confirm with the round-trip.

## What the tag triggers

Check `.github/workflows/` for a `push: tags:` trigger and tell the user what the tag kicks off.
Do not poll CI afterwards unless asked.

## Safety rules

- **Never create a GitHub Release object.** No `gh release create`, no release notes, no changelog
  body, no assets — not even in repositories that already have some. A pushed `v<version>` git tag
  _is_ the release. `gh` is deliberately absent from `allowed-tools`.
- Never start a release the user didn't ask for, and never invent the version number.
- Bump only the files the previous release bumped, plus `uv.lock` whenever `pyproject.toml`'s
  version moved.
- Never run a git command that writes. Git reads history here; jj does every mutation.
- If a step fails, stop and report — do not retry a rejected push with different flags.
- Never delete or move an existing tag. Once a tag is tracked — and `jj git fetch` tracks remote
  tags automatically — a local move or deletion rides out to the remote on the next
  `jj git push` or `jj git push --deleted`. Do not count on a safety check to catch it.
- Create lightweight tags: no annotation, no message, no signing.
