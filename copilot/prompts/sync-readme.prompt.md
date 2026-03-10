---
mode: "agent"
description: "Synchronize README.md with current project state"
---

# README Updater

Synchronize README.md with the actual current state of the project.

## When to Use

When README.md has drifted from reality, after major feature additions,
or when setup/deployment processes change.

## Steps

1. Read current `README.md`.
2. Read `docs/sessions/current-state.md` for latest project state.
3. Read `docs/architecture/overview.md` for system architecture.
4. Read `docs/setup/local-development.md` for setup steps.
5. Read `docs/setup/environment-variables.md` for env vars.

6. Update README.md to match reality. Sections to verify:
   - **Project description** — matches what the system actually does now
   - **Quick Start / Setup** — matches local-development.md
   - **Architecture section** — brief summary, links to `docs/architecture/`
   - **Current Status** — synced from current-state.md
   - **Environment Variables** — summary, links to full reference

7. Keep the README concise. It's an entry point, not the full documentation.
   Always link to `docs/` for detailed information.

8. Do not remove sections from the README template structure — update them.
