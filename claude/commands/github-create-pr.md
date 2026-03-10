Create a GitHub pull request using the repo's PR template.

Follow the instructions in `.claude/skills/github-create-pr/SKILL.md` exactly.

Detect the target branch, find the PR template (`.github/PULL_REQUEST_TEMPLATE.md` or fallback), auto-populate the PR body from the diff and commit log, and create a draft PR using `gh` CLI. Always present the full PR details to the user and get confirmation before creating.

$ARGUMENTS

If the skill file is not found, perform: verify `gh` CLI is available, detect default branch via `gh repo view`, find PR template in `.github/`, populate title (Conventional Commits) and body from diff/commits, present for approval, then create with `gh pr create --draft`. Never create a PR without user confirmation.
