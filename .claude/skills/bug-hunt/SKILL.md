---
name: bug-hunt
description: Deep bug hunt across a repository — prove defects, cover each with a red/green test in the existing suite, and publish each fix as its own atomic jj change on its own bookmark for CI. Use only when the user asks for a bug hunt, audit, or sweep for bugs. For debugging one known failure, or for committing work already done, do not use this skill.
---

# Deep bug hunt

Find concrete defects, prove each one, and publish each fix independently so CI starts early.

Invoking this skill authorizes pushing new fix bookmarks without asking per push. It does not
authorize opening a pull request, pushing trunk, or publishing a security fix — see the exceptions
below. A finding you cannot demonstrate is a line in the report, not a commit.

## Step 1: Preconditions and baseline

This skill requires a Jujutsu repository with a GitHub remote. If either is missing, stop before
changing anything — do not initialize jj, fall back to plain git, or push somewhere else.

Discover rather than assume:

```bash
jj bookmark list --all-remotes    # the remote and its trunk bookmark
jj log -r @ -T 'change_id'        # SAVE THIS — the starting change
```

- **The starting change ID.** Save it now and `jj edit` back to it on every exit path, including
  failures. The hunt moves the working copy repeatedly; leaving the user parked somewhere else is
  not an acceptable end state.
- **The test runner**, including how to run a single test.
- **The formatter and check gate** that has to pass before a push.

Then run the existing suite once to establish a **baseline**. Record what already fails. Anything on
that list is pre-existing and must not be reported as something the hunt introduced.

**Never set up a test suite.** If the repository has none, fixes still land; the report marks them
`no test coverage`.

## Step 2: Map the repository, then set the bug bar

Map every major production component before inspecting any of it. For each, look at public
boundaries, parsing and validation, error paths, state transitions, resource lifecycle, concurrency,
and platform-specific behavior.

**Do not stop at the first bug.** The hunt is done when every mapped component has been inspected
and every candidate is either fixed or classified report-only — not when the findings feel
sufficient.

When subagents are available, give them disjoint areas and read-only inspection. They return
candidates with a failure path and a reproduction idea; they never edit files, create changes, or
push. Reproduce every candidate yourself before acting on it.

A finding is landable only with a concrete failure path: specific inputs or state producing a wrong
output, a crash, corruption, or a violated invariant. State it in one sentence before writing any
code. If it cannot be stated that way, it is report-only.

Report-only regardless of how confident the finding feels:

- `.github/workflows/` and other CI configuration — surface it, never edit it
- Anything resting on a product or behavior judgment call (defaults, retry policy, ergonomics)
- Cosmetic, naming, or style findings
- Speculative hardening with no demonstrated failure
- Anything needing a new test suite, a new dependency, or a cross-cutting refactor

Report-only findings still appear in the final report with the reasoning. They just do not get a
bookmark.

## Step 3: Prove and fix each bug

In this order, inside the change:

1. Add the smallest regression test the existing harness can express.
2. Run it and capture the actual failure output. **If it passes here, the finding is wrong or the
   test is** — improve the test or drop the candidate.
3. Apply the narrowest fix.
4. Re-run the test, its surrounding suite, and the formatter and check gate.

Test and fix land in the same change. When no existing harness can express the failure, use a
focused deterministic reproduction, land only a clearly proven fix, and mark it `no test coverage`.

### Security exception

For a potentially exploitable bug, implement and test the fix locally and create its bookmark, but
**do not push it**. Pushing publishes the vulnerability alongside the fix. Give the user a concise,
non-exploitative summary and wait for explicit approval or disclosure direction.

## Step 4: Release risk

```bash
git tag --sort=-v:refname | head
```

No tags means the project is pre-release. Say that release-risk analysis was skipped and move on.

If any tag exists — **including a `0.x` or prerelease tag** — classify every fix independently:

| Level                    | What it means                                                                                                     |
| ------------------------ | ----------------------------------------------------------------------------------------------------------------- |
| **patch-safe**           | Restores clearly intended behavior. No API expansion, nothing a caller could reasonably have depended on.         |
| **minor-or-higher risk** | Changes documented output, defaults, validation, accepted inputs, public API, or behavior a caller could rely on. |

The goal is every change shipping alone as a low-risk patch. Caution explicitly when a fix is not
patch-safe, cannot ship alone, or is a behavior change wearing a bug's clothes.

## Step 5: Publish atomic changes

One bug, one change, one bookmark. Fetch fresh trunk before each independent change:

```bash
jj git fetch
jj new <trunk>@<remote> -m "one line, under 72 characters, why not what"
# test, fix, check
jj bookmark create <slug> -r @
jj git push --bookmark <slug>
```

- **Bookmark**: a bare descriptive slug, no prefix — `healthchecks-retry-backoff`. If the name
  already exists locally or on the remote, pick a more specific slug; never reuse it.
- **Message**: one line, under 72 characters, no body, no `Co-authored-by`.
- Push each fix as soon as its checks pass. Do not batch pushes to the end.
- Branch every independent change from freshly fetched trunk. Stack only when one fix is a genuine
  prerequisite of another, and record the dependency in the report.

Never push trunk, never force-push, never move or delete a pre-existing bookmark, and never run
`gh pr create` or `gh pr merge`.

If a push is rejected: preserve the local change and its bookmark, restore the starting change, and
**stop the entire hunt**. Report the exact failure. Do not retry with different flags.

## Step 6: Monitor CI

After each push, watch that bookmark's runs while continuing independent work:

```bash
gh run list --branch <slug>
gh run watch <run-id> --exit-status
gh run view <run-id> --log-failed
```

If the fix caused the failure, edit that same change, correct it, re-run local checks, and repush
the same bookmark. Failures from the workflow itself, from infrastructure, or from the step 1
baseline are report-only — never edit CI configuration to make a run go green. If no workflow starts
for the branch, say so plainly. Wait for every triggered run to finish before the final report.

## Step 7: Report and restore

Restore the saved starting change, then report one row per finding:

| Finding | Evidence | Bookmark or `report-only` | Test coverage | Depends on | CI  | Release risk |
| ------- | -------- | ------------------------- | ------------- | ---------- | --- | ------------ |

After the table, explain every report-only finding, stack dependency, CI exception, and release-risk
caution. Confirm that no pull requests were opened and that the starting change was restored.

## Safety rules

- **Never open a PR.** The user opens, reviews, and merges.
- Never push trunk, force-push, or move or delete a pre-existing bookmark.
- Never run `jj abandon`, `jj squash`, or `jj rebase` against another change.
- Never edit `.github/workflows/`.
- Never create a test suite, add a dependency, or start a refactor to make a fix possible.
- Never push a fix for a potentially exploitable bug without explicit approval.
- On a rejected push, stop the whole hunt and report — do not retry with different flags.
