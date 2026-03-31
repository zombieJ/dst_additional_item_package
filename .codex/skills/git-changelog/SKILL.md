---
name: "git-changelog"
description: "Generate commit messages or changelog text for this project. Use when the task is to inspect git changes, summarize diffs, or draft Conventional Commit messages on Windows/PowerShell."
---

# Git Changelog

Use this skill when the user wants:

- a commit message
- a changelog
- a summary of code changes
- a readable diff workflow on Windows PowerShell

## Workflow

1. Decide which diff is needed:
   - working tree: `git diff --no-pager`
   - staged: `git diff --cached --no-pager`
   - last commit: `git diff HEAD~1 HEAD --no-pager`
   - between refs: `git diff <ref1> <ref2> --no-pager`
2. If the diff needs to be preserved in a UTF-8 file, write it with PowerShell instead of shell redirection:

```powershell
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$output = git diff --cached --no-pager
[System.IO.File]::WriteAllText((Resolve-Path _diff.md).Path, $output, [System.Text.Encoding]::UTF8)
```

3. Read `_diff.md` only when a saved artifact is useful. Otherwise prefer reading command output directly.
4. Draft the final text in concise Conventional Commit style unless the user asked for another format.

## Rules

- Prefer `--no-pager` for git output in this environment.
- Do not use `git diff > _diff.md` on Windows PowerShell because encoding can become messy.
- Keep `_diff.md` in the repo root if you create it.
- Prefer short, high-signal summaries over line-by-line narration.

## Commit format

Use Conventional Commits by default:

```text
<type>(<scope>): <subject>
```

Common types:

- `feat`
- `fix`
- `refactor`
- `docs`
- `test`
- `chore`
- `perf`

