---
name: bug-hunt
description: Run an autonomous, whole-repository bug hunt that proves defects, adds red/green coverage in an existing test suite, and publishes each ordinary fix as an atomic Jujutsu bookmark for GitHub CI. Use only when the user explicitly invokes $bug-hunt in a Jujutsu repository with a GitHub remote; do not use for one known failure or work already in progress.
---

# Deep Bug Hunt

Find concrete defects, prove each one, and publish ordinary fixes independently so CI starts early.
The explicit invocation authorizes pushes of new fix bookmarks without per-push confirmation. Never
open a pull request or push to trunk. Treat security-sensitive findings as the exception described
below.

## 1. Prepare a clean hunt

1. Read the repository instructions and understand the product before looking for defects.
2. Require both a Jujutsu repository and a GitHub remote. Stop before making changes rather than
   initializing Jujutsu, falling back to Git, or pushing elsewhere.
3. Discover, without assuming:
   - the Git remote to fetch and push;
   - that remote's default trunk bookmark;
   - the existing test runner and single-test command;
   - the formatter, linter, and required local check gate.
4. Record the starting working-copy change ID and status so unrelated work can be restored exactly.
5. Fetch the selected remote, then create a fresh investigation change on fetched remote trunk:

   ```bash
   jj git fetch --remote <remote>
   jj new <trunk>@<remote> -m "Deep bug hunt"
   ```

Reuse this investigation change for the first confirmed fix and replace its placeholder description
with `jj describe --message "<message>"` before publishing it. Before every later independent fix,
fetch again and create another change from fetched remote trunk. On every terminal path, restore the
saved starting change with `jj edit <saved-change-id>`. Abandon the investigation change only when it
is verified empty, unbookmarked, and created by this run; never abandon another change.

If the remote, trunk, or repository identity is ambiguous, ask before fetching or pushing. If the
initial fetch fails, stop before changing code.

## 2. Audit the whole repository

Map every major production component and inspect its public boundaries, parsing and validation,
error paths, state transitions, resource lifecycle, concurrency, and platform-specific behavior.
Run the existing test suite or the broadest practical baseline and distinguish pre-existing failures
from regressions introduced during the hunt.

Do not stop after the first bug. Finish only after every mapped production component has been
inspected and every candidate has been fixed or classified as report-only.

When subagents are available, assign them disjoint areas for read-only inspection. Tell them to
return concrete candidates with the failure path and a reproduction or test idea. Do not let
subagents edit files, create changes, or push. The primary agent must reproduce every candidate.

Before writing code, state the candidate in one sentence as specific inputs or state producing a
wrong output, crash, corruption, or violated invariant. A finding without that concrete failure path
is report-only.

Keep these findings report-only even when plausible:

- CI configuration, including `.github/workflows/`; never edit it.
- Product or behavior judgment calls such as defaults, retry policy, or ergonomics.
- Cosmetic, naming, style, or speculative-hardening findings.
- Fixes requiring a new dependency, new test suite, or cross-cutting refactor.

## 3. Prove and fix each bug

For every landable bug with an existing suitable test suite:

1. Add the smallest regression test in the existing harness.
2. Run it before the fix and confirm it fails for the intended reason. If it passes, improve the
   test or reject the candidate.
3. Apply the narrowest fix.
4. Re-run the regression test, its surrounding suite, and the relevant formatter and check gate.

Keep the test and fix in the same change. Never create a test framework or suite. When no existing
harness can express the failure, use a focused deterministic reproduction, land only a clearly
proven fix, and mark it `no test coverage` in the report.

For a potentially exploitable security bug, implement and test the atomic fix locally but do not
push it. Create its local bookmark, give the user a concise non-exploitative summary, and ask for
explicit approval or disclosure direction before any remote publication.

## 4. Assess release risk

Inspect all Git tags:

```bash
git tag --sort=-v:refname
```

If there are no tags, say that release-risk analysis was skipped. If any tag exists, including a
`0.x` or prerelease tag, classify every fix independently:

- **patch-safe**: restore clearly intended behavior without an API expansion or behavior callers
  could reasonably depend on;
- **minor-or-higher risk**: change documented output, defaults, validation, accepted inputs, public
  API, or behavior a caller could plausibly rely on.

Caution explicitly when a fix is not a low-risk patch, cannot ship alone, or is actually a behavior
change rather than a defect correction.

## 5. Publish atomic changes

Use one bug, one change, and one bookmark. Describe the change with one line under 72 characters,
no body, and no `Co-authored-by`. Use a unique, short, bare hyphenated bookmark such as
`healthchecks-retry-backoff`; add no prefix. If that name already exists locally or remotely, choose
a more specific slug rather than moving or deleting it.

After the focused tests and checks pass:

```bash
jj bookmark create <slug> -r @
jj git push --remote <remote> --bookmark <slug>
```

Push each ordinary fix immediately rather than batching them. Branch every independent change from
freshly fetched remote trunk. Stack a change only when another fix is a genuine prerequisite, and
record the dependency in the report.

Never push trunk, force a push, move or delete a pre-existing bookmark, or run `gh pr create` or
`gh pr merge`. If a push is rejected, preserve the local change and bookmark, restore the starting
change, stop the entire hunt, and report the exact failure without retrying alternate flags.

## 6. Monitor GitHub CI

After each push, identify and watch runs for that bookmark while continuing independent work:

```bash
gh run list --branch <slug>
gh run watch <run-id> --exit-status
gh run view <run-id> --log-failed
```

If the fix caused a failure, edit the same Jujutsu change, correct it, rerun local checks, and repush
the same run-owned bookmark. Treat workflow, infrastructure, and unrelated baseline failures as
report-only; never edit CI configuration. If no branch workflow starts, report that plainly. Wait
for every triggered run to finish before the final report.

## 7. Report and restore

Restore the saved starting working-copy change, then report one row per finding:

| Finding | Evidence | Bookmark or `report-only` | Test coverage | Dependency | CI  | Release risk |
| ------- | -------- | ------------------------- | ------------- | ---------- | --- | ------------ |

After the table, explain every report-only finding, stack dependency, CI exception, and SemVer
caution. Confirm that no pull requests were opened and that the original working-copy change was
restored.
