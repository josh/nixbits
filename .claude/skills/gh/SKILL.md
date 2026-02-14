---
name: gh
description: GitHub issue management using the gh CLI. Use when working with GitHub issues - viewing, listing, triaging, or implementing fixes for issues.
allowed-tools: Bash(gh issue list:*), Bash(gh issue view:*), Bash(gh issue status:*), Bash(gh label list:*)
---

# GitHub Issue Management

Work with GitHub issues using the `gh` CLI.

## Read-only commands (always allowed)

```bash
gh issue list
gh issue list --state all
gh issue list --label "bug"
gh issue view <number>
gh issue view <number> --comments
gh issue status
gh label list
```

## Modification commands (ask first)

These commands modify state - confirm with the user before running:

```bash
gh issue create --title "Title" --body "Description"
gh issue edit <number> --add-label "label"
gh issue edit <number> --add-assignee @me
gh issue close <number> --comment "Reason"
gh issue reopen <number>
gh issue comment <number> --body "Comment text"
```

## Before creating an issue

Each repository has its own conventions. Before drafting a new issue:

1. **Study existing issues**: Run `gh issue list` and `gh issue view` on several recent issues to learn the preferred title format and body structure
2. **Fetch all labels**: Run `gh label list` to see available labels and choose the most appropriate ones

Match the style and conventions you observe in the existing issues.

## Fixing an issue

When asked to fix an issue:

1. **Understand the issue**: Run `gh issue view <number> --comments`
2. **Identify affected code**: Search the codebase for relevant files
3. **Implement the fix**: Make minimal, focused changes
4. **Test the changes**: Run relevant tests
5. **Create a commit**: Reference the issue number (e.g., "Fix #123: description")

## Arguments

When invoked with `/gh <number>`, view that issue:

```bash
gh issue view $ARGUMENTS --comments
```
