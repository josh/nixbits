---
name: clean-room
description: Clean-room rewrite of named files — mask the originals, reconstruct them from the surrounding code alone, validate, then unmask and report a pro/con comparison for the user to decide on. Use only when the user names files to rewrite clean-room, from scratch, or without looking at the current implementation. For an ordinary refactor, rewrite, or cleanup of a file, do not use this skill.
---

# Clean-room rewrite

Mask the named files, reconstruct them from the code that surrounds them, then unmask and compare.

Rewriting a file with the current implementation in front of you produces a paraphrase. The existing
text anchors structure, naming, and shortcuts, so the rewrite inherits whatever was wrong with the
original and cannot tell you which parts of it were essential. Reconstructing from the constraints
alone — callers, tests, types, docs — makes that separation visible.

Invoking this skill authorizes moving the named files out of the working tree. It does not authorize
committing, pushing, or choosing between the two versions. The run ends with a dirty working copy
and a report; the user decides what survives.

The rewrite is only worth what its provenance is worth. Most of this skill is the discipline of
keeping a dozen incidental paths back to the original closed, plus an honest admission when one
opens.

## Phase 0: Preconditions

The line is **content, not command**. A VCS command that prints only file names — `jj status`,
`git status --short`, `git add -N` — is allowed in any phase. Every command that can print a file's
contents is banned from phase 1 until phase 4, and there is no phase in which one is needed:

```bash
jj status            # or: git status --short — file names, never file contents
```

Require a clean working copy and every target tracked and committed. An untracked or uncommitted
target means the quarantine copy is the only copy in existence; say so and get an explicit yes
before touching it.

Confirm the target list back to the user. Then discover and **write down** the project's check gate
— the test, lint, format, and build commands that have to pass. Record it now. Phase 3 must not go
rediscovering it by reading build output, which is one of the leak channels.

## Phase 1: Mask

Quarantine outside the working tree, so no `Glob` or `Grep` scoped to the repository can reach it:

```bash
QUARANTINE=$(mktemp -d /tmp/clean-room.XXXXXX)   # SAVE THIS PATH — it holds the only loose copy
mkdir -p "$QUARANTINE/$(dirname <path>)"
mv <path> "$QUARANTINE/<path>"                   # mv — never rm, never git rm, never the Trash
```

**`mv`, not `rm`.** A deleted file is recoverable only through the VCS commands the next phase bans,
which turns an ordinary undo into a contamination event. Do not commit the deletion.

**Only the originals leave the repository.** The rewrite is written in place, at the real paths, and
every later phase runs against the working tree as it normally would. The quarantine is storage, not
a workspace — nothing is built, tested, or edited inside it. Do not move the work out of the
repository to keep it away from the originals; that breaks the test runner, the formatter, and any
build that resolves paths relative to the project root, and it is not what keeps the room clean.

Then sweep the remaining tree for copies of what was just masked: a vendored second copy under
another name, a `testdata/` golden file, `__snapshots__` or `*.snap`, a doc quoting the file in a
fenced block, a generated `.d.ts`. A remaining file reproducing the target verbatim or
near-verbatim is **not** clean-room input — quarantine it too, or name it off-limits in the brief,
and record it in the final report. A doc that _describes_ the file is legitimate input; one that
_reproduces_ it is not.

## Phase 2: Rewrite

Delegate to one `general-purpose` subagent for the whole file set. The files may be interdependent,
and a subagent's fresh context is the actual clean-room guarantee — it holds regardless of what this
session read before the skill was invoked.

**The brief carries as little as possible**: the target paths, the user's stated intent if they gave
one, the check gate, the off-limits list from phase 1, and the ban list below verbatim. It must not
contain your own description of the original. This session may already be contaminated, and a
recollection launders that contamination straight into the brief. The subagent does its own
discovery.

Legitimate input for the subagent: the target's path and name, sibling and calling code, tests that
exercise it, type signatures inferred from call sites, docs and README prose, the user's brief.

The ban list binds the subagent and this session both, from phase 1 until phase 4 opens it:

| Channel                | Closed                                                                                                                                                                                                                                     |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| VCS content            | `git show`, `cat-file`, `diff`, `log -p`, `blame`, `grep <rev>`, `stash show -p`, `archive`, `fsck`, reflog; `jj show`, `diff`, `file show`, `log -p`, `interdiff`                                                                         |
| VCS resurrection       | `jj undo`, `jj op restore`, `jj op log -p`, `jj restore`, `git checkout -- <path>`, `git restore` — these bring the masked file back silently                                                                                              |
| Repo internals on disk | `.git/` and `.jj/` — objects, packfiles, `ORIG_HEAD`, `COMMIT_EDITMSG`, `.jj/repo/store`, `.jj/working_copy`                                                                                                                               |
| Host copies            | `gh api …/contents`, `gh pr diff`, `gh release download`, `gh browse`, `gh run view --log` (CI logs echo source); web fetches of the repository, of `raw.githubusercontent.com`, or of an upstream project the file vendors                |
| Build output, caches   | `dist/`, `build/`, `target/`, `out/`, `.next/`, `node_modules/.cache/`, `__pycache__/`; sourcemaps, which embed the original verbatim; coverage HTML, which embeds annotated source; generated API docs; `/nix/store/*-source/`, `result/` |
| Editor and OS detritus | `*.orig`, `*.rej`, `*~`, `.#*`, `*.swp`; JetBrains `.idea/shelf/` and Local History; VS Code `History/`; `~/.Trash`; `tags`, `cscope.out`                                                                                                  |
| Agent-side             | Memory search for the duration of the run; session transcripts under `~/.claude/projects/`; prior scratchpad files; any `CLAUDE.md` or `AGENTS.md` section quoting the file                                                                |
| The quarantine         | `$QUARANTINE` is off-limits to Read, Grep, Glob, and `cat` until phase 4                                                                                                                                                                   |

If the original is seen anyway — a stray sourcemap, a `jj undo` reflex, an editor swapfile — the
rewrite is **contaminated**. Say so in the report, plainly, and name the channel. Do not continue
quietly and present it as clean-room. A rewrite claiming a provenance it does not have is worse than
no rewrite at all.

## Phase 3: Validate

Run the phase 0 check gate against the new files. On failure, send the failures back to the **same**
subagent — its context is intact and still clean, where a new agent would restart discovery from
nothing.

A gate that builds from a **source-filtered** copy of the tree — Nix flakes, Bazel, anything reading
the VCS file list rather than the filesystem — will not see the rewrite until it is tracked, and
fails claiming the path does not exist. That is the tracking gap, not a broken rewrite. Clear it
with a name-only command:

```bash
jj status            # snapshots new files; or, in plain git: git add -N <path>
```

Both print file names only and neither reads content, so both stay inside the phase 0 exemption.
Reaching for `git stash`, `git checkout`, or a commit to make the gate see the file is the wrong
move — those are content-bearing and end the clean room.

**Scrub failure output before forwarding it.** Snapshot assertions, golden-file diffs, and doctests
print the original's content in their failure messages, and pasting one hands the subagent exactly
what phase 1 took away. If the output embeds the original, summarize it in your own words instead,
and record the near-miss in the report.

Three rounds. If the gate still fails, stop and ask whether to unmask anyway — a failing rewrite is
still worth comparing, but that call is the user's, not a unilateral move into phase 4.

## Phase 4: Unmask and compare

The ban lifts here and only here. The rewrite stays in place at the real path; the original stays in
quarantine and is read from there. Do not restore `.orig` files into the tree, where the formatter
and the check gate will pick them up.

```bash
diff -u "$QUARANTINE/<path>" "<path>"
```

Report one section per file:

| Axis             | What to state                                                              |
| ---------------- | -------------------------------------------------------------------------- |
| Interface parity | Signatures or exports that moved, and every caller affected                |
| Behavior parity  | Where the two agree; where they diverge, and which one is right            |
| **New-only**     | What the rewrite does that the original never did — the ideas worth taking |
| **Old-only**     | What the original did that the rewrite lacks                               |
| Size and deps    | Line count delta, dependencies added or dropped                            |

Flag every old-only behavior as **likely encoding history the rewrite could not know** — a guard for
an input nobody would predict, a workaround for an upstream bug, an ordering constraint someone
found the hard way. These are the reason the comparison exists. The default assumption is that they
carry forward, not that the rewrite improved on them by leaving them out.

Close with the four outcomes and let the user pick: keep the rewrite; restore the original; keep the
rewrite and graft the old-only behaviors back in; or restore the original and graft in the new-only
ideas.

Absent a decision, the end state is the rewrite in place, the originals in quarantine, nothing
committed, and the quarantine path stated so it can be restored by hand. Committing is a separate
step — hand off to `jj-describe`.

## Safety rules

- Never run a content-bearing VCS command between phase 1 and phase 4.
- Never `jj undo` or `jj op restore` during a run — it resurrects the masked files silently.
- Never `rm` a target; `mv` it to quarantine. Never delete the quarantine.
- Never commit, push, or create a bookmark. The run ends with a dirty working copy.
- Never search memory during a run.
- Never present a contaminated rewrite as clean-room.
- Never restore the original over the rewrite unless the user says so.
- If the check gate cannot be made to pass in three rounds, stop and ask.
