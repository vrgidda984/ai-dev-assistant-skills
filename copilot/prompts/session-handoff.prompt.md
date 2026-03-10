---
mode: "agent"
description: "End-of-session handoff — save state for the next developer"
---

# Session Handoff

Generate a complete session handoff so the next developer (or your next session) can pick up seamlessly.

## When to Use

End of any coding session, or when switching context to another developer.

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

   [What the next developer should pick up, in priority order]

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
