Force update all project documentation based on recent code changes.

Follow the instructions in `.claude/skills/update-docs/SKILL.md` exactly.

Review git diff and conversation context to identify what changed, then update all relevant docs.

If the skill file is not found, check git diff, update relevant docs in `docs/architecture/` and `docs/setup/`, append to `docs/sessions/changelog.md`, and check if README.md is stale.
