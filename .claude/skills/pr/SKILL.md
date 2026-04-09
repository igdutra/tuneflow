---
name: pr
description: Create a concise GitHub pull request for the current branch against `main`. Use whenever the user wants to open a PR, create a pull request, or submit their branch for review.
---

# /pr

Create a clear, minimal GitHub pull request for the current branch targeting `main`.

## Workflow

Do not perform extra validation beyond the listed workflow. In particular, do not check for an existing PR or verify upstream/push state unless the user explicitly asks.

1. Detect the current branch with `git branch --show-current`.
2. Gather context before writing the PR:
   - `git status --short`
   - `git log --oneline main..$(git branch --show-current)`
   - `git diff --stat main...$(git branch --show-current)`
3. Assume the branch is already pushed and there is no existing PR. If that assumption is wrong, stop.
4. Keep the PR small and clearly scoped to the current branch.
5. Write a short title and a short body with:
   - Why
   - What changed
6. Use `gh pr create`.

## Guardrails

- Do not create or amend commits.
- Do not merge.
- Be fast. Do the minimum needed to open a clear PR.
