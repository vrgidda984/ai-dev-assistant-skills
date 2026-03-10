End-of-session handoff. Generate a complete session handoff for the next developer.

Follow the instructions in `.claude/skills/session-handoff/SKILL.md` exactly.

Update `docs/sessions/current-state.md` (overwrite entirely) and append to `docs/sessions/changelog.md`. Check if `README.md` and architecture docs need updating.

If the skill file is not found, perform a basic session handoff: overwrite `docs/sessions/current-state.md` with current system state, recent changes, working/in-progress/blocked status, and next steps. Append a dated entry to the TOP of `docs/sessions/changelog.md`.
