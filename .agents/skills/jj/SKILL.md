---
name: jj
description: How to work in Jujutsu (jj) — the working-copy model, stacking, splitting and squashing, rebasing onto trunk, conflicts, bookmarks, revsets, and undo. Use when operating on history in a jj repository beyond describing the current change. For describing or committing the current change, use jj-describe; for a tagged release, use jj-release.
---

# Jujutsu (jj)

jj is not git with renamed commands. The working copy is a commit, rewriting history is routine,
branches are bookmarks that never move on their own, and the operation log makes every step
undoable. Work with that model instead of translating git habits one command at a time.

## Orient first

```bash
jj status
jj log -r 'trunk()..@'
jj op log --limit 5
```

There is no "current branch". Name the change, bookmark, or revset each command should act on. Flags
change between jj releases — when one is uncertain, check `jj help <command>` rather than guessing.

## Mental model

- `@` is the working-copy commit. File edits land in it automatically; there is no index.
- `@-` is its parent. After `jj commit`, the finished work is `@-` and `@` is a new empty change.
- Every change has a **change ID** (stable across rewrites) and a **commit ID** (changes on every
  rewrite). Refer to changes by change ID.
- Bookmarks are named pointers for publishing. Committing does not advance them.
- Rewriting a mutable change auto-rebases its descendants.
- Conflicts are recorded in commits. A rebase always completes; resolving comes after.

## Git to jj

| Git                               | jj                                                          |
| --------------------------------- | ----------------------------------------------------------- |
| `git add` / staging               | `jj split`, `jj squash <paths>`, `jj restore <paths>`       |
| `git commit -m`                   | `jj commit -m` (or `jj describe -m` + `jj new`)             |
| `git commit --amend`              | edit in place, or `jj squash` from a child                  |
| `git checkout` / `git switch`     | `jj new <rev>` to build on it, `jj edit <rev>` to change it |
| `git pull --rebase`               | `jj git fetch` then `jj rebase -b @ -o 'trunk()'`           |
| `git rebase -i`                   | `jj rebase`, `jj split`, `jj squash`, `jj edit`             |
| `git reflog` / `git reset --hard` | `jj op log`, `jj undo`, `jj op restore`                     |
| `git stash`                       | `jj new @-` — the old `@` stays in the graph                |
| `git rebase --continue`           | nothing — resolve the conflicted commit directly            |

## Never open an editor or TUI

You cannot drive an interactive diff editor or a message editor. Any command that falls back to
one hangs or fails.

- Always pass `-m` to `describe`, `commit`, `new`, and `split`.
- `jj squash` opens an editor when both source and destination have descriptions. Pass `-u` to keep
  the destination's message, or `-m` to set one.
- Never use `-i`/`--interactive`, `--tool`, `jj diffedit`, or bare `jj resolve`.

Select by path instead of by hunk:

```bash
jj split -m "msg" <paths>                    # named paths become the first change, the rest stays in @
jj split -p -m "msg" <paths>                 # same, but as siblings instead of parent and child
jj squash <paths>                            # move those paths from @ into @-
jj squash --from <rev> --into <rev> <paths>  # move them between any two changes
jj restore --from <rev> <paths>              # reset paths in @ to their contents in <rev>
jj absorb                                    # fold each edit into the ancestor that last touched those lines
```

A split within a single file is done by editing: move the unwanted hunks out of the file, `jj new`,
then put them back. If that is impractical, ask the user to run `jj split -i`.

## Workflows

**Describe first, then edit.** Start with intent, and let `@` evolve under one change ID:

```bash
jj new 'trunk()' -m "Add parser"
```

**Scratch child.** Keep a polished `@-` and experiment in `@`, then fold the good parts down with
`jj squash <paths>` and discard the rest with `jj abandon @` or `jj restore`.

**Stacks.** Each change on top of the previous one. To fix an earlier change, either `jj edit <id>`
and edit it directly, or `jj new <id>`, make the fix, and `jj squash`. Descendants rebase
automatically either way. `jj new -B @ -m "msg"` inserts a new change below `@` and moves the
working copy into it.

**Independent changes.** Start each from `jj new 'trunk()'` so none depends on another.
`jj parallelize <revs>` turns an accidental stack into siblings.

**Leave `@` where you found it.** Before moving elsewhere, save `jj log -r @ -T change_id --no-graph`
and `jj edit` back to it when done, including on failure.

## Rebasing

```bash
jj rebase -b <rev> -o <dest>   # the whole branch containing <rev> that isn't already in <dest>
jj rebase -s <rev> -o <dest>   # <rev> and its descendants
jj rebase -r <rev> -o <dest>   # only <rev>; its children are reparented onto its parent
```

`-A <rev>` / `-B <rev>` insert after or before a revision instead of `-o`. `-d` is an old alias of
`-o`. Fetch before rebasing onto a remote: `jj git fetch`, then `jj rebase -b @ -o 'trunk()'`.

## Revsets

Quote every revset in the shell. Preview a revset with `jj log -r '<revset>'` before passing it to a
command that mutates.

| Revset                                 | Meaning                                |
| -------------------------------------- | -------------------------------------- |
| `@`, `@-`, `@+`                        | working copy, its parent, its children |
| `::x`, `x::`, `x..y`                   | ancestors, descendants, range          |
| `trunk()`                              | the default remote's main bookmark     |
| `trunk()..@`                           | the local line of work                 |
| `remote_bookmarks()..@`                | not yet pushed                         |
| `mine()`, `empty()`, `conflicts()`     | by author, empty, conflicted           |
| `subject("text")`                      | exact first line of the description    |
| `description(substring:"text")`        | description contains text              |
| `heads(x)`, `roots(x)`, `latest(x, n)` | the tips, bases, or n newest of a set  |

`description(exact:"...")` rarely matches, because descriptions end in a newline. Use `subject()`.

## Conflicts

```bash
jj log -r 'conflicts()'
jj new <conflicted-rev>        # work on top of it
jj resolve --list              # the conflicted paths
# edit the conflict markers out of those files
jj squash                      # move the resolution into the conflicted change
```

Resolving the bottom-most conflicted change often clears its descendants too. Re-check
`conflicts()` afterwards.

## Bookmarks and pushing

Edit commits; publish bookmarks.

```bash
jj bookmark create <name> -r <rev>
jj bookmark move <name> --to <rev>
jj bookmark set <name> -r <rev>          # create or move
jj bookmark advance --to <rev>           # move the closest bookmark below <rev> up to it
jj git push --bookmark <name> --dry-run
jj git push --bookmark <name>
jj git push --change <rev>               # push under a generated bookmark name
```

After rewriting a pushed change, move its bookmark to the new commit and push again. jj
force-pushes safely, and only when the remote still matches what it last saw.

## Recovery

```bash
jj undo                        # reverse the last operation (repeatable)
jj op log                      # every operation, newest first
jj op show <op>
jj op restore <op>             # put the whole repo back to that operation
jj evolog -r <change>          # earlier versions of one change
```

The operation log is local. It does not cover ignored files or anything outside the repository.

## Rules

- Never push unless the user asks. Name exact bookmarks, and never use `--all` unless asked.
- Commit messages follow jj-describe: one line, under 72 characters, why rather than what.
- Never pass `--ignore-immutable`, or move or delete a bookmark you did not create, without asking.
- In a repository colocated with git, use git only to read. After any git write, run `jj status` so
  jj imports it.
- Before a large rewrite, note the current operation from `jj op log --limit 1` so it can be
  restored.
- When invoked as `$jj` in Codex or `@jj` in ChatGPT, apply these rules to the task the user
  describes; no positional argument is required.
