---
name: gh
description: Manage GitHub issues with the gh CLI by viewing, listing, triaging, creating, editing, commenting on, closing, reopening, or implementing fixes. Use only for GitHub issue workflows, not pull requests or general GitHub operations.
---

# GitHub Issue Management

Work with GitHub issues using the `gh` CLI.

## Inputs

Use the issue number and requested action from the user's prompt. When the user explicitly invokes
`$gh` in Codex or `@gh` in ChatGPT with only an issue number, view that issue and its comments. If
a requested action needs information the user did not provide, ask rather than infer it.

```bash
gh issue view <number> --comments
```

## Read-only commands

Use these without an additional workflow-level confirmation. Continue to honor any approval the
host requires for network access or command execution.

```bash
gh issue list
gh issue list --state all
gh issue list --label "bug"
gh issue view <number>
gh issue view <number> --comments
gh issue status
gh label list
```

## Modification commands

Before running a command that changes GitHub state, state the exact change and obtain the user's
confirmation.

```bash
gh issue create --title "Title" --body "Description"
gh issue edit <number> --add-label "label"
gh issue edit <number> --add-assignee @me
gh issue close <number> --comment "Reason"
gh issue reopen <number>
gh issue comment <number> --body "Comment text"
```

## Create an issue

Before drafting or creating an issue:

1. Run `gh issue list` and inspect several recent issues to learn the repository's title and body
   conventions.
2. Run `gh label list` and choose only labels that already exist.
3. Match the observed style and show the exact proposed issue to the user before creating it.

## Fix an issue

When asked to fix an issue:

1. Run `gh issue view <number> --comments` and understand the complete request.
2. Search the repository for the affected code.
3. Implement a minimal, focused fix.
4. Run the relevant tests.
5. Create a commit that references the issue number, for example `Fix #123: description`.

Do not modify GitHub state merely because the issue was used as implementation context.
