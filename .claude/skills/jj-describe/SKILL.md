---
name: jj-describe
description: Jujutsu VCS describe workflow. Use when the user asks to commit or describe changes in a jj repository.
allowed-tools: Bash(jj show:*), Bash(jj describe:*)
---

# Jujutsu (jj) Commit Workflow

In jj, the working copy (`@`) is always a mutable change. There is no staging area — all file changes are automatically tracked.

## Step 1: Understand current state

```bash
jj show
```

## Step 2: Draft a commit message

- Summarize the nature of changes (new feature, bug fix, refactoring, etc.)
- Focus on the **why**, not the **what**
- The first line MUST be under 72 characters
- Only write one line
- Do NOT add "Co-authored-by"

## Step 3: Apply the message

Use `jj describe` to set the message on the current working copy change. Never use `jj commit` or `jj new`.

```bash
jj describe --message "Commit message here"
```

## Safety rules

- Never push unless explicitly asked
- Never use `jj commit`, `jj new`, `jj abandon`, `jj squash`, or `jj rebase`
- If there are no changes (empty diff), inform the user instead of describing
- Writing more than 72 characters and more than one will be rejected

## Arguments

When invoked as `/jj`, describe the current working copy changes using `jj describe`.

## Tip

Seriously, only write a single concise one line commit message.
