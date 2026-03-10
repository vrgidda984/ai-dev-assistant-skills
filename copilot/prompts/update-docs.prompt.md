---
mode: "agent"
description: "Update project documentation after code changes"
---

# Update Documentation

Scan recent changes and update all relevant documentation.

## When to Use

After any significant code change, or when docs are noticed to be stale.

## Steps

1. Identify what changed by checking `git diff --stat` or reviewing
   conversation context.

2. For each category of change, update the corresponding doc:

   | Change Type                         | Doc to Update                               |
   | ----------------------------------- | ------------------------------------------- |
   | System architecture                 | `docs/architecture/overview.md`             |
   | API endpoints                       | `docs/architecture/api-contracts.md`        |
   | Infrastructure / IaC / Deployment   | `docs/architecture/infrastructure.md`       |
   | Database schema / entities          | `docs/architecture/data-model.md`           |
   | Environment variables               | `docs/setup/environment-variables.md`       |
   | Technical decision made             | New ADR in `docs/decisions/` using template |
   | Setup or deployment process         | Relevant file in `docs/setup/`              |

3. Append an entry to the TOP of `docs/sessions/changelog.md`:

   ```markdown
   ## [YYYY-MM-DD] — [Brief Title]

   - **What changed**: [description]
   - **Why**: [reasoning]
   - **Files affected**: [key files]
   - **Breaking changes**: [yes/no — details if yes]
   ```

4. Check if `README.md` is now out of sync with the project state. Update if so.

5. Verify the "Last updated" dates on modified docs are current.

6. Summarize what was updated.

## Notes

- When in doubt, update the doc. Over-documenting beats stale docs.
- Make surgical updates — don't rewrite sections that are still accurate.
- Write for a developer who has never seen this codebase.
