---
mode: "agent"
description: "End-of-session handoff — save state for your next session"
---

# Session Handoff

Save your current working context so you can pick up seamlessly in your next session.

## When to Use

End of any coding session, when context gets too long, or when starting a fresh thread.

## Steps

1. Review all changes made in this session by checking git diff (if available)
   or recalling from conversation context.

2. Overwrite `docs/sessions/current-state.md` entirely with this structure:

   ```markdown
   # Current State

   _Last updated: [YYYY-MM-DD]_

   ## System Overview

   [What the system does right now — 2-3 sentences]

   ## Recent Changes

   [What was changed in this session and why]

   ## Current Status

   - **Working**: [what's functional and tested]
   - **In Progress**: [what's partially done]
   - **Blocked**: [blockers or open questions, if any]

   ## Next Steps

   [What to pick up next, in priority order]

   ## Key Context

   [Anything non-obvious — gotchas, workarounds, temporary hacks,
   pending decisions, things that look wrong but are intentional]
   ```

3. Append to the TOP of `docs/sessions/changelog.md`:

   ```markdown
   ## [YYYY-MM-DD] — [Brief Title]

   - **What changed**: [description of changes]
   - **Why**: [reasoning behind the changes]
   - **Files affected**: [list of key files changed]
   - **Breaking changes**: [yes/no — details if yes]
   ```

4. Check if `README.md` needs updating based on changes made. Update if so.

5. Check if any architecture docs in `docs/architecture/` are now stale.
   Update if needed.

6. Confirm the handoff is complete and summarize what was captured.

## Note

`docs/sessions/` is local working state — it should be added to your project's `.gitignore`.
