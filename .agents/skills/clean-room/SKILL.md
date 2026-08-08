---
name: clean-room
description: Perform a clean-room rewrite of named, tracked files by quarantining the originals, reconstructing them from surrounding code with a context-isolated subagent, validating the rewrite, and comparing both versions. Use only when a user explicitly invokes $clean-room in Codex or @clean-room in ChatGPT and names files to rebuild from scratch without reading the current implementation; do not use for ordinary refactors, rewrites, or cleanups.
---

# Clean-Room Rewrite

Mask the named files, reconstruct them from the code that surrounds them, then unmask and compare.
Invoke this skill as `$clean-room` in Codex or `@clean-room` in ChatGPT.

Rewriting a file with the current implementation in view produces a paraphrase. The existing text
anchors structure, naming, and shortcuts, so the rewrite inherits whatever was wrong with the
original and cannot reveal which parts were essential. Reconstructing from constraints alone—callers,
tests, types, and prose documentation—makes that separation visible.

Explicit invocation authorizes moving the named files out of the working tree. It does not authorize
committing, pushing, or choosing between versions. End with a dirty working copy and a report; let the
user decide what survives.

The rewrite is only worth what its provenance is worth. Keep incidental paths back to the original
closed, and disclose any path that opens.

## Phase 0: Establish Preconditions

Treat the line as **content, not command**. A VCS command that prints only file names—`jj status`,
`git status --short`, or `git add -N`—is allowed in every phase. Ban every command that can print a
file's contents from phase 1 until phase 4; none is needed during that interval.

```bash
jj status            # or: git status --short — file names, never file contents
```

Before moving anything, verify that context-isolated delegation is available. In Codex, require
`spawn_agent` with `fork_turns: "none"`. In ChatGPT, require an equivalent delegation control that
starts a subagent with no inherited conversation context and returns a reusable handle. Do not test
delegation by starting an agent while the originals remain visible. If isolated delegation is
unavailable, stop before masking; do not substitute an inherited-context agent or perform the
rewrite in the current session.

Require a clean working copy and every target to be tracked and committed. An untracked or
uncommitted target means the quarantine copy may be the only copy in existence; explain that risk
and obtain an explicit yes before touching it.

Confirm the target list with the user. Discover and write down the project's check gate—the test,
lint, format, and build commands that must pass. Record it now. Do not rediscover the gate during
phase 3 by reading build output, which is a leak channel.

## Phase 1: Mask the Originals

Quarantine outside the working tree so repository-scoped search and listing operations cannot reach
the originals:

```bash
QUARANTINE=$(mktemp -d /tmp/clean-room.XXXXXX)   # Save this path: it holds the loose originals
mkdir -p "$QUARANTINE/$(dirname <path>)"
mv <path> "$QUARANTINE/<path>"                   # Use mv, never rm, git rm, or the Trash
```

Use `mv`, not `rm`. Recovering a deleted file requires the VCS operations banned in the next phase,
turning an ordinary undo into a contamination event. Do not commit the deletion.

Move only the originals out of the repository. Write the rewrite in place at the real paths, and
run every later phase against the normal working tree. Treat quarantine only as storage: do not
build, test, or edit inside it. Moving the entire work out of the repository breaks tools that
resolve paths from the project root and does not strengthen isolation.

Sweep the remaining tree for copies of each masked target: vendored duplicates, golden files under
`testdata/`, snapshots such as `__snapshots__/` or `*.snap`, documentation containing fenced copies,
generated declarations, and similar artifacts. A remaining file that reproduces a target verbatim
or nearly verbatim is not legitimate clean-room input. Quarantine it too or put it on the
subagent's off-limits list, and record it in the final report. Documentation that describes behavior
is legitimate; documentation that reproduces implementation is not.

## Phase 2: Reconstruct in an Isolated Context

Use exactly one context-isolated subagent for the entire target set because the files may be
interdependent. The fresh context is the clean-room guarantee even if the current session saw the
originals before invocation.

In Codex, call `spawn_agent` with `fork_turns: "none"`, then retain the returned agent ID or canonical
task name. In ChatGPT, start one subagent with conversation inheritance disabled and retain its
thread or handle. Use that same handle for all phase 3 repair rounds; never replace it with a new
agent. Send the task only after masking is complete.

Keep the brief minimal: include only the target paths, the user's stated intent, the recorded check
gate, the phase 1 off-limits list, and the ban list below verbatim. Do not include a description or
summary of the originals. The current session may already be contaminated, and recollection would
launder that contamination into the isolated context. Let the subagent discover constraints itself.

Legitimate inputs are target paths and names, sibling and calling code, tests that exercise the
targets, type signatures inferred from call sites, descriptive documentation, and the user's brief.

The following bans bind both the primary session and the subagent from phase 1 until phase 4:

| Channel | Closed |
| --- | --- |
| VCS content | `git show`, `cat-file`, `diff`, `log -p`, `blame`, `grep <rev>`, `stash show -p`, `archive`, `fsck`, and reflog; `jj show`, `diff`, `file show`, `log -p`, and `interdiff` |
| VCS resurrection | `jj undo`, `jj op restore`, `jj op log -p`, `jj restore`, `git checkout -- <path>`, and `git restore`; these can silently bring masked files back |
| Repository internals | `.git/` and `.jj/`, including objects, packfiles, `ORIG_HEAD`, `COMMIT_EDITMSG`, `.jj/repo/store`, and `.jj/working_copy` |
| Host copies | Repository content or diffs through `gh`, other hosting APIs, raw-content URLs, releases, CI logs that echo source, or web copies of the repository or an upstream project whose file was vendored |
| Build output and caches | `dist/`, `build/`, `target/`, `out/`, `.next/`, cache directories, bytecode caches, sourcemaps, coverage HTML, generated API docs, `/nix/store/*-source/`, and `result/` |
| Editor and OS detritus | `*.orig`, `*.rej`, `*~`, `.#*`, `*.swp`, editor shelves or local history, OS trash, `tags`, and `cscope.out` |
| Agent-side history | Memory or conversation-history search; Codex or ChatGPT session transcripts, exports, traces, prior scratchpads, or repository instruction files that quote a target |
| Quarantine | `$QUARANTINE` is off-limits to every file read, search, directory listing, shell expansion, and other access until phase 4 |

If anyone sees an original through a stray sourcemap, resurrection command, editor backup, or any
other channel, mark the rewrite **contaminated**. Name the channel plainly in the final report. Do
not continue quietly and present the result as clean-room; false provenance is worse than no rewrite.

## Phase 3: Validate the Rewrite

Run the phase 0 check gate against the new files. On failure, send a scrubbed failure summary back
to the same isolated subagent. In Codex, use `followup_task` with the retained handle instead of
calling `spawn_agent` again. In ChatGPT, continue the same delegated thread. Its context remains
intact and clean; a new agent would lose its discovery work.

A gate that builds from a source-filtered tree—such as Nix flakes, Bazel, or anything using the VCS
file list—may not see an untracked rewrite and may report that the path is missing. Treat this as a
tracking gap, not a broken rewrite. Clear it with a name-only command:

```bash
jj status            # Snapshots new files
git add -N <path>    # Plain Git alternative
```

Both commands print only file names and remain within the phase 0 exemption. Do not use `git stash`,
`git checkout`, a restore command, or a commit to make the gate see the rewrite; those operations
are content-bearing or resurrect originals and end the clean room.

Scrub failure output before forwarding it. Snapshot assertions, golden-file diffs, and doctests can
print original content in their failure messages. If output embeds an original, summarize the
failure in your own words instead and record the near-miss in the report.

Run at most three validation-and-repair rounds. If the gate still fails, stop and ask whether to
unmask anyway. A failing rewrite may still be worth comparing, but entering phase 4 is the user's
decision.

## Phase 4: Unmask and Compare

Lift the ban only now. Keep the rewrite at its real path and read the original from quarantine. Do
not restore `.orig` files into the tree, where formatters and check gates may pick them up.

```bash
diff -u "$QUARANTINE/<path>" "<path>"
```

Report one section per file:

| Axis | State |
| --- | --- |
| Interface parity | Signatures or exports that moved and every affected caller |
| Behavior parity | Where versions agree, where they diverge, and which behavior is correct |
| **New-only** | What the rewrite does that the original never did—the ideas worth taking |
| **Old-only** | What the original did that the rewrite lacks |
| Size and dependencies | Line-count delta and dependencies added or removed |

Flag every old-only behavior as **likely encoding history the rewrite could not know**: an
unpredictable input guard, an upstream workaround, or an ordering constraint learned the hard way.
Assume those behaviors should carry forward unless evidence shows otherwise; discovering them is
the purpose of the comparison.

Close with four choices and let the user decide: keep the rewrite; restore the original; keep the
rewrite and graft old-only behaviors back in; or restore the original and graft in new-only ideas.

Without a decision, leave the rewrite in place, leave the originals in quarantine, commit nothing,
and state the quarantine path so the user can restore by hand. Treat committing as a separate step;
in a Jujutsu repository, hand it off to `$jj-describe`.

## Safety Rules

- Never run a content-bearing VCS command between phase 1 and phase 4.
- Never run `jj undo` or `jj op restore`; they can silently resurrect masked files.
- Never delete a target or quarantine. Move targets into quarantine with `mv`.
- Never commit, push, or create a bookmark. End with a dirty working copy.
- Never search memory, conversation history, transcripts, or prior traces during a run.
- Never use more than one isolated subagent, and retain its handle for validation follow-ups.
- Never present a contaminated rewrite as clean-room.
- Never restore an original over a rewrite without the user's direction.
- If the check gate cannot pass in three rounds, stop and ask.
