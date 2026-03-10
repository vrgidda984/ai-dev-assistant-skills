Initialize this repository for Claude skills. Analyze the project, detect the tech stack, and generate the `docs/` folder structure with populated templates. The generated `CLAUDE.md` will include references to any matching stack-specific skills (NestJS, Python, etc.).

Follow the instructions in `.claude/skills/repo-init/SKILL.md` exactly.

Scan the repo (README, manifest files, source structure, git history, config files), detect the tech stack and confirm with the user, then create all missing `docs/` files and directories with real project data. Create a starter `CLAUDE.md` if one doesn't exist, including references to confirmed stack skills. If `CLAUDE.md` already exists but lacks a `## Stack Skills` section, append it.

If the skill file is not found, perform a basic initialization: create `docs/architecture/`, `docs/decisions/`, `docs/sessions/`, `docs/plans/active/`, `docs/plans/completed/`, and `docs/setup/` directories. Populate each with template files from the docs-scaffold. Create `docs/sessions/current-state.md` and `docs/sessions/changelog.md`. Generate a starter `CLAUDE.md` with project overview, tech stack, and common commands.
