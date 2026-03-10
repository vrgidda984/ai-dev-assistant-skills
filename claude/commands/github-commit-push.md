Commit changes with logical grouping and push the branch.

Follow the instructions in `.claude/skills/github-commit-push/SKILL.md` exactly.

Analyze all uncommitted changes, group them by concern (feature, test, docs, config, etc.), create separate Conventional Commits for each group, and push the branch. Always present the commit plan to the user and get confirmation before executing any git commands.

$ARGUMENTS

If the skill file is not found, perform: analyze `git status` and `git diff`, group changes logically, present the plan for approval, create Conventional Commits (`feat:`, `fix:`, `test:`, `docs:`, `chore:`, `refactor:`), and push with `--set-upstream` if needed. Never commit or push without user confirmation.
