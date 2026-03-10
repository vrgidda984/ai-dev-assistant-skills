---
mode: "agent"
description: "Resume work by loading latest project state and recent changes"
---

# Resume Session

Read the current project state to get up to speed before starting work.

## When to Use

At the start of any coding session, especially if you're picking up work
from a previous session or another developer.

## Steps

1. Read `docs/sessions/current-state.md` for the latest project state snapshot.

2. Read the top 3 entries in `docs/sessions/changelog.md` for recent changes.

3. Check `docs/plans/active/` for any in-flight feature plans.

4. Read `.github/copilot-instructions.md` for project coding standards.

5. Summarize for the user:
   - **System overview**: What the project does
   - **Recent changes**: What was done in the last session(s)
   - **Current status**: What's working, in progress, and blocked
   - **Next steps**: What should be tackled next
   - **Active plans**: Any feature plans that are in flight

6. Ask the user what they'd like to work on, or suggest picking up
   from the next steps listed in the current state.
