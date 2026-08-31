---
name: jj-describe
description: Describe the current Jujutsu working-copy change with a concise commit message. Use when the user asks to commit or describe ordinary changes in a jj repository; do not use for tagged releases.
---

# Jujutsu Describe Workflow

In Jujutsu, the working copy (`@`) is always a mutable change. There is no staging area; all file
changes are automatically tracked.

## Describe the current change

1. Inspect the current change:

   ```bash
   jj show --git
   ```

2. If the diff is empty, tell the user and stop.
3. Draft exactly one line that summarizes why the change exists:
   - Keep it under 72 characters.
   - Do not add a body.
   - Do not add `Co-authored-by`.
4. Apply the message to the current working-copy change:

   ```bash
   jj describe --message "Commit message here"
   ```

## Safety rules

- Never push unless the user explicitly asks.
- Never run `jj commit`, `jj new`, `jj abandon`, `jj squash`, or `jj rebase`.
- Never run `jj tag`. Tagging a release belongs to jj-release, not to this skill.
- Do not perform any mutation other than `jj describe` as part of this workflow.
- When invoked as `$jj-describe` in Codex or `@jj-describe` in ChatGPT, describe the current
  working-copy change; no positional argument is required.
