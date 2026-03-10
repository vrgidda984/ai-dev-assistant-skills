---
name: github-create-pr
description: >
  Create a GitHub pull request using the repo's PR template if one exists.
  Auto-populates the PR body from the diff and commit log. Creates as draft.
  Requires user confirmation before creating the PR.
  Use when the user says "create PR", "open a pull request", "make a PR",
  or invokes /github-create-pr.
---

# GitHub Create PR

Create a draft pull request on GitHub, using the repo's PR template and auto-populating from the diff and commit history.

## When to Use

When the user wants to create a pull request for the current branch.

## Prerequisites

- Must be in a git repository with a GitHub remote
- Current branch must have commits ahead of the target branch
- `gh` CLI must be installed and authenticated (`gh auth status`)
- Branch should already be pushed (suggest running `/github-commit-push` first if unpushed commits exist)

## Steps

### 1. Validate environment

- Verify `gh` CLI is available: `which gh`
- Verify authentication: `gh auth status`
- If either fails, inform the user with installation/auth instructions and stop.

### 2. Detect target branch

Determine the default branch of the repository:

```bash
gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name'
```

This typically returns `main` or `master`.

### 3. Gather context

Collect information to populate the PR:

- **Current branch**: `git branch --show-current`
- **Commit log**: `git log <default-branch>..HEAD --oneline`
- **Full diff summary**: `git diff <default-branch>..HEAD --stat`
- **Detailed diff** (for understanding changes): `git diff <default-branch>..HEAD` (read selectively for large diffs)

### 4. Find PR template

Search for a PR template in this order:

1. `.github/PULL_REQUEST_TEMPLATE.md`
2. `.github/pull_request_template.md` (lowercase variant)
3. `.github/PULL_REQUEST_TEMPLATE/` directory — use `default.md` if it exists, otherwise the first `.md` file
4. `PULL_REQUEST_TEMPLATE.md` in repo root
5. `docs/pull_request_template.md`

If no template is found, use the default template below.

### 5. Populate the PR

**Title**: Generate from the branch name and commit history:
- Convert branch name to human-readable form (e.g., `feature/user-auth` → `feat: add user authentication`)
- Or summarize from commits if the branch name is not descriptive
- Follow Conventional Commits format for the title

**Body**: Fill in the template sections:
- **Summary/Description**: Write a concise overview of what changes and why, derived from the diff
- **Changes**: List the key changes, grouped logically (from commit messages and diff stat)
- **Testing**: Note what tests were added/modified, or flag if tests are missing
- Fill in any other template sections as best as possible from the available context
- For checklist items in the template, check off items that are clearly satisfied

### 6. Present to user for review (REQUIRED)

Display the complete PR details:

```
Pull Request Details:

Title: feat: add user authentication
Target: main ← feature/user-auth
Mode: Draft

Body:
---
## Summary
Added JWT-based authentication with login and register endpoints.

## Changes
- Added AuthController with /login and /register routes
- Added AuthService with JWT token generation
- Added User entity and CreateUserDto
- Added unit tests for auth service

## Testing
- [x] Unit tests added for AuthService
- [ ] E2E tests (not yet added)
---

Create this draft PR? [confirm/edit/cancel]
```

**Wait for user confirmation.** If the user wants edits, adjust and present again.

### 7. Create the PR

```bash
gh pr create --draft --title "<title>" --body "<body>" --base "<target-branch>"
```

### 8. Output result

Display:
- PR URL (from `gh pr create` output)
- PR number
- Target branch
- Draft status

## Default PR Template

When no repo template exists, use:

```markdown
## Summary

[Auto-generated summary of what changed and why]

## Changes

[Bullet list of key changes, derived from commits and diff]

## Testing

[Description of test coverage — what was tested, what's missing]
```

## Human-in-the-Loop

This skill MUST get explicit user confirmation before:
- Creating the pull request

Never create a PR without the user reviewing and approving the title, body, and target branch.

## Slash Command Fallback

If this skill doesn't auto-trigger, use: `/github-create-pr`
