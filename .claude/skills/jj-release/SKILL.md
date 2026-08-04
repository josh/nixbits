---
name: jj-release
description: Cut and push a tagged release in a jj repository colocated with git. Use only when the user names a version to release, cut, or tag (e.g. "release 0.7.1", "ship a patch version"). For committing, describing, or pushing ordinary work — including bumping a version string without tagging — use jj-describe instead.
allowed-tools: Bash(git log:*), Bash(git show:*), Bash(git tag:*), Bash(git push:*), Bash(git ls-remote:*), Bash(jj log:*), Bash(jj diff:*), Bash(jj status:*), Bash(jj describe:*), Bash(jj bookmark:*), Bash(jj git push:*), Read, Edit
---

# Release workflow (jj colocated with git)

**Confirm before running anything.** This skill gets invoked when `jj-describe` was meant. State the
package, version, and trunk bookmark you are about to release and wait for a yes. No version number
in the request means it was almost certainly a mistake — ask, don't infer one.

**jj cannot push tags.** This is a jj limitation, not a missing flag waiting to be found.
`jj git push` pushes **bookmarks only** — there is no `--tag`. `jj tag set` writes a tag to the
local store but has no way to publish it. Do not go looking for a jj incantation.

The workaround: **jj owns the commit, git owns the tag's entire lifecycle** — create, push, verify.
This works because the repository is colocated: both tools write the same object store, and jj
imports the git-created tag on its next command. Reaching for `git tag` and
`git push origin v<version>` here is the correct path, not a fallback.

## Step 1: Find the last release tag and read it

Nothing about the release shape is assumed — read it off the last one.

```bash
git tag --sort=-v:refname | head -3         # the last release tag
git show <previous-tag>                     # commit subject AND the files carrying the version
git log <previous-tag>..<trunk> --oneline   # what is actually unreleased
```

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

## Step 3: Commit and push (jj)

Resolve the trunk bookmark rather than assuming `main`:

```bash
jj describe --message "<package name> <version>"
jj bookmark set <trunk> -r @
jj git push --bookmark <trunk>
```

A `Bypassed rule violations` line means an admin bypass carried the push past a
required-status-checks ruleset — that is success, not a warning. A hard rejection means the release
needs a PR instead; stop and ask.

## Step 4: Tag the pushed SHA (git)

Tag the **pushed SHA**, not `HEAD` — jj rewrites commit ids as the working copy moves, so re-read
it after the push:

```bash
SHA=$(jj log -r <trunk> --no-graph -T 'commit_id')
git tag v<version> "$SHA"
git push origin v<version>
```

A lightweight tag — no `-a`, no `-m`, no signing.

## Step 5: Confirm

```bash
git ls-remote origin refs/heads/<trunk> refs/tags/v<version>
```

Both should print the same SHA. Report that plainly. **The pushed tag is the whole release** — stop
here.

## What the tag triggers

Check `.github/workflows/` for a `push: tags:` trigger and tell the user what the tag kicks off.
Do not poll CI afterwards unless asked.

## Safety rules

- **Never create a GitHub Release object.** No `gh release create`, no release notes, no changelog
  body, no assets — not even in repositories that already have some. A pushed `v<version>` git tag
  _is_ the release. `gh` is deliberately absent from `allowed-tools`.
- Never start a release the user didn't ask for, and never invent the version number.
- Bump only the files the previous release bumped.
- Never reach for a jj tag command — see the top of this file.
- If a step fails, stop and report — do not retry a rejected push with different flags.
- Never delete or move an existing tag.
