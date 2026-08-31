---
name: jj-release
description: Cut and push a versioned release in a Jujutsu repository colocated with Git. Use only when the user explicitly asks to release, cut, or tag a named version. Do not use for ordinary commits, pushes, or version bumps without a tag; use jj-describe instead.
---

# Release Workflow for Jujutsu Colocated with Git

**Confirm before running any command or editing any file.** State the package, version, and trunk
bookmark you are about to release, then wait for an explicit yes. Treat an invocation without a
version number as likely accidental: ask for the version and do not infer one.

Jujutsu owns the entire release: describe, bookmark, tag, and push. `jj tag set` creates the tag and
`jj git push --bookmark <trunk> --tag v<version>` publishes both refs in one command. Use Git only to
read history during this workflow; never run a Git command that writes.

## 1. Find and inspect the previous release

Read the release shape from the latest existing release:

```bash
git for-each-ref --sort=-v:refname --format='%(refname:short)' refs/tags | head -3
git show <previous-tag>
git log <previous-tag>..<trunk> --oneline
```

The sort must be version-aware. A lexicographic sort ranks `v0.9.0` above `v0.10.0`, which reads the
wrong release as the latest and bumps from the wrong base. `-v:refname` sorts by version; check any
substitute against that case before trusting it.

Use `git show` to determine both:

- **The file set:** Identify exactly which files carried the previous version and which occurrences
  changed. Preserve quoting and update every linked occurrence together.
- **The commit subject:** Confirm the repository follows the subject convention below. If it
  differs, follow the repository's established convention.

If the unreleased changes suggest a different bump level, mention that once and continue with the
version the user requested. If no prior tag exists, ask the user for the version-file set instead
of guessing.

## Release formats

| Artifact       | Format                              | Example     |
| -------------- | ----------------------------------- | ----------- |
| Commit subject | `<package name> <version>` — no `v` | `foo 1.4.0` |
| Git tag        | `v<version>` — always a `v`         | `v1.4.0`    |

Use a one-line commit subject with no prefix, body, `Co-authored-by`, or change summary. Use the
package name established by the repository or previous release.

## 2. Bump and verify

Edit only the files changed by the previous release, then verify that the diff has the same shape:

```bash
jj diff --stat
```

Stop if any other file moved. If the working copy already contains unrelated changes, ask before
including them in the release change.

Keep `pyproject.toml` and `uv.lock` in lockstep. The lockfile records the project's own version, so
a version bump in `pyproject.toml` leaves it stale. Re-lock before verifying the diff:

```bash
uv lock
```

Include `uv.lock` in every release that bumps a version in `pyproject.toml`. Apply this rule even if
the previous release omitted the lockfile; that omission is a mistake to avoid repeating, not a file
set to copy. This does not apply when the version is dynamic — for example `hatch-vcs` or
`setuptools-scm` — and `pyproject.toml` carries no version string. If `uv lock` changes anything
beyond the project's own version entry, report that drift before committing.

## 3. Describe, tag, and push with Jujutsu

Resolve the trunk bookmark from the repository rather than assuming `main`:

```bash
jj describe --message "<package name> <version>"
jj bookmark set <trunk> -r @
jj tag set v<version> -r <trunk>
jj git push --bookmark <trunk> --tag v<version>
```

Run these in order. `jj tag set` resolves `<trunk>`, so moving the bookmark first is what places the
tag on the release commit rather than on its parent. No commit ID needs to be read or copied, and a
later commit ID rewrite cannot strand the tag.

Push the bookmark and the tag in one command. Pushing only the tag publishes the release commit under
that tag while leaving `<trunk>` on the parent commit, which releases a version that is not on the
branch.

Name the exact tag. `--tag` matches glob patterns and `--all` pushes every bookmark and tag; neither
belongs in a release.

If `jj tag set` reports that it refuses to move the tag, the version is already released. Stop and
ask the user; do not pass `--allow-move`.

Treat `Bypassed rule violations` as a successful admin bypass of required status checks. If the
push is rejected, stop and explain that the release needs a pull request; do not retry with
different flags.

## 4. Confirm the remote refs

```bash
git ls-remote origin refs/heads/<trunk> refs/tags/v<version>
```

Both refs must resolve to the same SHA. Report that plainly and stop; the pushed tag is the entire
release.

`git ls-remote` queries the remote, whereas `jj tag list -a` shows only Jujutsu's local record of
what it last pushed or fetched. Confirm with the remote query.

## Report tag-triggered automation

Inspect `.github/workflows/` for a `push: tags:` trigger and tell the user what the tag starts. Do
not poll CI unless asked.

## Safety rules

- Never create a GitHub Release object, release notes, changelog body, or release assets. Do not run
  `gh release create` or any other `gh release` command.
- Never start a release the user did not request or invent a version number.
- Bump only the files the previous release bumped, plus `uv.lock` whenever the version in
  `pyproject.toml` moved.
- Never run a Git command that writes. Git reads history in this workflow; Jujutsu performs every
  mutation.
- Stop and report any failed step; do not retry a rejected push with different flags.
- Never delete, move, or replace an existing tag. Once a tag is tracked — and `jj git fetch` tracks
  remote tags automatically — a local move or deletion is published on the next `jj git push` or
  `jj git push --deleted`. Do not count on a safety check to catch it.
- Create lightweight tags: no annotation, no message, no signing.
- When invoked as `$jj-release` in Codex or `@jj-release` in ChatGPT, take the requested version
  from the prompt rather than expecting a positional argument.
