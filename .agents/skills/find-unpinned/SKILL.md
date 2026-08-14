---
name: find-unpinned
description: Survey a repository for unpinned and floating dependency versions and report where each could be pinned to a concrete version or digest. This workflow is read-only and never edits files. Use when the user asks what is unpinned, floating, or reproducible, or where dependency pins are missing. For refreshing versions that are already pinned, use bump-pins instead.
---

# Find Unpinned Dependencies

Find dependencies that were never pinned, assess whether pinning each one is worthwhile, and report
the concrete pin when it can be resolved authoritatively. Never edit files, create changes or
bookmarks, push, or open a pull request.

Pinning replaces invisible drift with visible staleness. Recommend it only when automation or a
documented human workflow can keep the pin current. Treat a deliberately floating dependency as a
result and explain why it should remain floating.

## 1. Inspect update automation

Read the repository instructions and inspect `.github/dependabot.yml`, `renovate.json`, and other
dependency-update configuration before inventorying floats. Record which ecosystems have automated
updates.

Unlike `$bump-pins`, automation is evidence in favor of pinning here: a bot-managed digest can move
when upstream releases, while an unmaintained digest can silently become stale. Include the
responsible automation in the report.

## 2. Inventory floating dependencies

Search the whole repository, including hidden CI configuration, container definitions,
devcontainers, install scripts, manifests, and prose. Order findings by blast radius rather than by
file. Executing remotely controlled code outranks a broad library constraint.

| Shape                        | Example                                       | Candidate pin                                                         |
| ---------------------------- | --------------------------------------------- | --------------------------------------------------------------------- |
| Action on a branch           | `uses: owner/action@main`                     | A release tag plus its commit SHA.                                    |
| Unversioned installer        | `curl -sSf https://.../install.sh \| sh`      | A versioned artifact URL plus a checksum, when upstream provides one. |
| Action on a major tag        | `uses: actions/checkout@v4`                   | An exact release, optionally its commit SHA with a version comment.   |
| Rolling base image           | `FROM alpine` or `FROM node:22`               | An exact tag, plus a digest when maintainable.                        |
| Versioned download, no check | `.../download/v1.2.3/tool.tar.gz`             | Keep the version and add checksum verification.                       |
| Toolchain channel            | `go-version: stable` or `node-version: lts/*` | An exact version unless the row intentionally tracks latest.          |
| Nix fetcher on a moving ref  | `rev = "main"` in `fetchFromGitHub`           | A commit SHA with the corresponding source hash.                      |
| Pre-commit branch revision   | `rev: main`                                   | A release tag.                                                        |
| Manifest range, no lockfile  | `"foo": "^1.2.3"` without a lockfile          | Commit the ecosystem's lockfile.                                      |
| Implicit latest              | `image: registry/app`                         | An explicit tag.                                                      |

Group duplicate occurrences of the same dependency, but keep one report row per site so every
location remains actionable.

## 3. Exclude values that are already pinned

Do not report:

- dependency ranges backed by a committed lockfile such as `package-lock.json`, `uv.lock`,
  `Cargo.lock`, or `go.sum`;
- Nix flake inputs backed by a committed `flake.lock`;
- `pkgs.<name>` references pinned transitively by the locked nixpkgs input;
- Kubernetes API groups, configuration schema versions, module-path major suffixes, or runtime
  interpolations that merely resemble versions.

Treat movement of an existing lockfile or concrete version as `$bump-pins` work, not an unpinned
dependency finding. Mention important sites that looked floating but were lockfile-pinned in the
final report.

## 4. Decide what should remain floating

Apply these rules before recommending a pin:

- Keep a latest-tracking matrix row floating. It is a compatibility canary, and pinning it removes
  the signal it exists to provide.
- Recommend an image digest only when automation can keep it current. A rolling minor image tag
  may receive security fixes that an abandoned digest will not.
- Do not convert dependency ranges in a published library into exact pins. Those ranges describe
  compatibility for downstream solvers; applications use lockfiles for reproducibility.
- Treat `runs-on: ubuntu-latest` as a policy decision about when to absorb runner migrations, not a
  straightforward dependency pin. Mention it after the table at most.
- When a vendor offers no versioned artifact, report the exposure and the absence of a supported
  pin instead of inventing one.

If the purpose of a floating row or whether a package is a published library is ambiguous, inspect
the surrounding configuration and repository documentation. Ask the user only when the decision
cannot be established safely from the repository.

## 5. Resolve concrete pins opportunistically

Use authoritative upstream sources to resolve current releases and immutable identifiers. Prefer
available read-only web or CLI tools. Useful commands include:

```bash
gh release list --repo <owner>/<repo> --limit 5
gh api repos/<owner>/<repo>/commits/<tag> --jq .sha
skopeo inspect --format '{{.Digest}}' docker://<image>:<tag>
crane digest <image>:<tag>
nix store prefetch-file --json <url>
```

Check that a CLI is installed before using it. Do not install tooling merely to resolve a digest.
If no available tool can resolve one, leave the digest blank and explain why. Never guess or
fabricate a release, commit SHA, image digest, or checksum.

## 6. Report findings

Report one row per site, ordered from most consequential to least:

| Site | Floating value | Proposed pin | Digest | Change risk | Maintained by |
| ---- | -------------- | ------------ | ------ | ----------- | ------------- |

Use `path:line` for `Site`. Classify the risk of making the change:

- **low:** mechanical; the proposed pin is exactly what resolves now;
- **medium:** requires automation to remain current or represents a policy choice;
- **high:** would remove a compatibility signal or break downstream consumers, so explain it
  instead of recommending it.

For `Maintained by`, name the bot, `$bump-pins`, a documented human workflow, or `nothing`. After the
table, explain every float deliberately left alone, unresolved digest, and significant site that is
already lockfile-pinned. Confirm that the repository was not changed and offer to apply a selected
subset in a separate task.

## Safety Rules

- Remain read-only. Never edit files or mutate Git, Jujutsu, GitHub, registries, or other remote
  state.
- Never fabricate a digest, checksum, commit SHA, or latest version.
- Never report a range backed by a committed lockfile as unpinned.
- Never recommend pinning a row that intentionally tracks latest.
- Never recommend exact dependency versions in a published library manifest.
- Never install tooling to resolve a pin.
