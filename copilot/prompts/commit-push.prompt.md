---
mode: "agent"
description: "Analyze changes, create Conventional Commits, and push"
---

# GitHub Commit & Push

Analyze uncommitted changes, group them logically, create Conventional Commits, and push the branch.

## When to Use

When you want to commit and push current changes with well-structured commit messages.

## Prerequisites

- Must be in a git repository
- Must have uncommitted changes (staged, unstaged, or untracked files)

## Steps

### 1. Assess the working tree

Run these commands to understand the current state:
- `git status --porcelain` — list all changed/untracked files
- `git diff` — unstaged changes
- `git diff --cached` — staged changes
- `git branch --show-current` — current branch name
- `git remote -v` — verify remote exists

If there are no changes, inform the user and stop.

### 2. Analyze and group changes

Review every changed file and its diff. Group files by logical concern:

| Group | Files | Commit prefix |
|-------|-------|---------------|
| Feature code | New/modified source files implementing functionality | `feat:` |
| Bug fixes | Source changes that fix broken behavior | `fix:` |
| Tests | Test files (`*.test.*`, `*.spec.*`, `__tests__/`, `test/`) | `test:` |
| Documentation | Markdown files, JSDoc-only changes, `docs/` | `docs:` |
| Configuration | `package.json`, `tsconfig.json`, `.eslintrc`, CI files, `.env.example` | `chore:` |
| Refactoring | Restructuring without behavior change | `refactor:` |
| Styling | Formatting-only changes (whitespace, semicolons, etc.) | `style:` |

**Guidelines:**
- If ALL changes belong to one logical group, create a single commit.
- If changes span multiple concerns, split into separate commits.
- Within a group, keep related files together (e.g., a component and its test can go in the same `feat:` commit if they implement the same feature).
- Use your judgment — the goal is meaningful, reviewable commits, not maximum granularity.

### 3. Present the plan to the user (REQUIRED)

Before executing ANY git commands, present the full commit plan:

```
Proposed commits:

1. feat: add user authentication endpoint
   Files: src/auth/controller.ts, src/auth/service.ts, src/auth/dto.ts

2. test: add auth endpoint unit tests
   Files: src/auth/controller.spec.ts, src/auth/service.spec.ts

3. docs: document auth API in README
   Files: README.md

Branch: feature/user-auth
Push to: origin/feature/user-auth (new upstream)

Proceed? [confirm/edit/cancel]
```

**Wait for user confirmation before proceeding.** If the user wants changes, adjust the plan and present again.

### 4. Execute the commits

For each group (in dependency order — e.g., source before tests):
1. `git add <files>` — stage only the files in this group
2. `git commit -m "<type>: <description>"` — commit with Conventional Commits message
   - Add a commit body (separated by blank line) if the change warrants explanation
   - Keep the subject line under 72 characters

### 5. Push the branch

- Check if an upstream tracking branch exists: `git rev-parse --abbrev-ref @{upstream} 2>/dev/null`
- If upstream exists: `git push`
- If no upstream: `git push --set-upstream origin <branch-name>`

### 6. Summarize

Output a summary:
- Number of commits created
- Each commit's hash (short), type, and message
- Push result (branch, remote, any new upstream set)

## Commit Message Format

Follow Conventional Commits:

```
<type>(<optional scope>): <description>

[optional body]
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`, `build`, `ci`, `perf`

## Human-in-the-Loop

This prompt MUST get explicit user confirmation before:
- Staging and committing files
- Pushing to remote

Never execute git write operations without approval.
