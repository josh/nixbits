---
name: find-unpinned
description: Survey a repository for unpinned and floating dependency versions and report where each could be pinned to a concrete version or digest. Read-only — it never edits. Use when the user asks what is unpinned, floating, or reproducible, or where pins are missing. For refreshing versions that are already pinned, use bump-pins instead.
---

# Find unpinned dependencies

`bump-pins` finds pins that have gone stale. This finds the dependencies that were never pinned at
all — `uses: actions/checkout@v4`, `FROM alpine`, `curl … | sh`, `go-version: stable`. Those never
show up as drift because there is nothing to drift from; they quietly resolve to something different
on every run.

**This skill only reads.** It changes no files, creates no changes or bookmarks, and pushes nothing.
The output is a table and an explanation. If the user wants a float pinned afterwards, they ask.

Pinning is not free. A pin converts an invisible risk — drift — into a visible one — staleness. That
trade only pays off when something can move the pin later: Dependabot, Renovate, or a human running
`bump-pins`. A pin nobody maintains is a dependency frozen at whatever version happened to be
current the day someone ran this skill. Most of this file is about which floats to leave alone.

## Step 1: Read the automation config first

```bash
cat .github/dependabot.yml renovate.json 2>/dev/null
```

The inversion from `bump-pins` matters. There, an ecosystem a bot already covers is off-limits.
**Here it is the opposite: bot coverage is evidence the pin is maintainable**, which is the single
biggest factor in whether pinning is worth recommending. A `github-actions` entry means a digest pin
gets a pull request when upstream moves; without one, that same digest pin is where the dependency
goes to rot.

Record which ecosystems have automation. The report needs a column for it.

## Step 2: Inventory the floats

Search the whole repository, including CI configuration, container definitions, devcontainers,
install scripts, and prose. Order the findings by blast radius, not by file — a float that executes
someone else's code during a build outranks a caret range every time.

| Shape                        | Example                                      | Proposed pin                                                           |
| ---------------------------- | -------------------------------------------- | ---------------------------------------------------------------------- |
| Action on a branch           | `uses: owner/action@main`                    | Tag plus commit sha. Highest value in the repository — arbitrary code. |
| Unversioned installer        | `curl -sSf https://…/install.sh \| sh`       | A versioned artifact URL and a sha256. Report it if upstream has none. |
| Action on a major tag        | `uses: actions/checkout@v4`                  | Exact `4.2.2`, optionally `@<sha> # v4.2.2`.                           |
| Rolling base image           | `FROM alpine`, `FROM node:22`                | `node:22.11.0`, plus a digest if one resolves. See step 4 first.       |
| Versioned download, no check | `curl -L …/download/v1.2.3/foo.tar.gz`       | Already versioned. The missing pin is the sha256 verification step.    |
| Toolchain channel            | `go-version: stable`, `node-version: lts/*`  | An exact version — unless this is the latest-tracking row. See step 4. |
| Nix fetcher on a moving ref  | `rev = "main"` in `fetchFromGitHub`          | A commit sha, with the hash recomputed against it.                     |
| `pre-commit` branch rev      | `rev: main`                                  | A release tag.                                                         |
| Manifest range, no lockfile  | `"foo": "^1.2.3"` with no lockfile committed | Commit the lockfile. The lockfile is the pin, not a rewritten range.   |
| Implicit `latest`            | `image: registry/app` with no tag            | An explicit tag. An absent tag is `latest` spelled quietly.            |

## Step 3: Already pinned, despite appearances

These match a floating shape but are not findings. Recognize them rather than rediscovering them
every run:

- **A caret or tilde range with a committed lockfile.** `package-lock.json`, `uv.lock`, `Cargo.lock`,
  `go.sum` — the lockfile is the pin, and the range above it is a solver constraint. Moving it is
  `bump-pins`' job. Only an _uncommitted_ lockfile makes the range a finding.
- **A flake input without a rev.** `flake.lock` pins it. Confirm the lock is committed and move on.
- **`pkgs.<name>` in Nix.** Pinned by the nixpkgs input, transitively by `flake.lock`.
- The same version-shaped non-versions `bump-pins` lists: `apiVersion: v1` and `batch/v1`, a schema
  `version: 2` at the top of a config file, a `/v2` module-path suffix, and `${{ … }}`
  interpolations that resolve at run time.

## Step 4: Floats that should stay floating

This is the judgement, and it is most of the value of the run:

- **A latest-tracking matrix row is a canary, not an oversight.** A job pinned to `stable` or
  `latest` exists to break early when upstream does, so the breakage arrives as a red build instead
  of as a surprise months later. Pinning it deletes the signal. This is the exact mirror of
  `bump-pins`' rule about compatibility rows carrying a channel comment; the two skills have to
  agree, or they will undo each other.
- **A rolling minor image tag still receives security patches.** `alpine:3.22` gets CVE fixes;
  `alpine:3.22.1@sha256:…` gets whatever was current when it was written. Recommend a digest here
  only where step 1 found automation that can move it, and say so in the row.
- **Library manifests declare compatibility, not pins.** `>=1.0` in a published library's
  requirements is a promise to consumers about what it works with; pinning it exactly breaks their
  solver. Applications pin, libraries range. Check whether the thing being packaged is published
  before reporting its floors.
- **`runs-on: ubuntu-latest` is a policy call.** GitHub does retire runner images, so pinning
  `ubuntu-24.04` is defensible, but it is a choice about when to absorb migrations, not drift.
  A note under the table, at most.
- **A vendor with no versioned artifact.** Some install scripts genuinely have no pinnable URL.
  Report the fact and what the exposure is. Do not invent a pin that does not exist upstream.

A float left deliberately is a result. Say which ones and why.

## Step 5: Resolve the concrete value, opportunistically

Check the tool is present before reaching for it, and drop the digest silently when nothing on the
machine can produce one. **Never fabricate a digest, and never report a "latest" version that did
not come from an authoritative source.** A guessed sha256 is worse than an empty column.

```bash
gh release list --repo <owner>/<repo> --limit 5                # newest release
gh api repos/<owner>/<repo>/commits/<tag> --jq .sha            # action digest
skopeo inspect --format '{{.Digest}}' docker://<image>:<tag>   # image digest; or: crane digest
nix store prefetch-file --json <url> | jq -r .hash             # artifact hash; or: curl -sL <url> | sha256sum
```

## Step 6: Report

One row per site, most consequential first:

| Site | Floating value | Proposed pin | Digest | Risk | Maintained by |
| ---- | -------------- | ------------ | ------ | ---- | ------------- |

`Site` is `path:line`. `Risk` is the risk of _making the change_, not of leaving it:

- **low** — mechanical and safe; the pinned value is exactly what resolves today.
- **medium** — needs automation to stay current, or is a policy decision the user should make.
- **high** — would delete a compatibility signal or break downstream consumers. Explain rather than
  recommend.

`Maintained by` is what would move the pin afterwards: a bot from step 1, `bump-pins`, or nothing.
"Nothing" is the column that turns a low-risk row into one worth arguing about.

After the table, cover every float deliberately left alone with its reason, every digest that could
not be resolved and why, and every site that looked floating but is lockfile-pinned. Close by
confirming that nothing was changed, and offer to apply a subset if the user wants it.

## Safety rules

- **Read only.** No file edits, no `jj` or `git` mutations, no pushes, no pull requests. If the user
  wants pins applied, that is a separate, explicitly requested task.
- Never fabricate a digest, a hash, or a latest version that was not read from upstream.
- Never report a range backed by a committed lockfile as unpinned.
- Never recommend pinning a row that exists to track latest.
- Never recommend pinning a published library's dependency floors.
- Do not install tooling to resolve a digest — use what is already available, or leave the column
  empty and say so.
