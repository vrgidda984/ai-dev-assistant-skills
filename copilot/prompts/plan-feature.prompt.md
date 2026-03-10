---
mode: "agent"
description: "Create a structured feature plan before writing code"
---

# Plan Feature

Create a structured plan document before any code is written.

## When to Use

Before starting any new feature, integration, or significant change.

## Steps

1. Discuss the feature with the user to understand:
   - What it should do (acceptance criteria)
   - How it fits into the existing architecture
   - Any constraints, dependencies, or timeline

2. Read `docs/architecture/overview.md` to understand current system state.

3. Check `docs/plans/active/` for any related or conflicting plans.

4. Create a new plan file at `docs/plans/active/[feature-name].md`:

   ```markdown
   # Feature: [Name]

   _Created: [YYYY-MM-DD]_
   _Status: Active_
   _Author: [who planned this]_

   ## Goal

   [What this feature accomplishes — 1-2 sentences]

   ## Context

   [Why we're building this, what problem it solves, any background]

   ## Approach

   [Technical approach — which services, modules, APIs are involved.
   Reference existing architecture from docs/architecture/overview.md]

   ## Tasks

   - [ ] [Task 1 — be specific and actionable]
   - [ ] [Task 2]
   - [ ] [Task 3]
   - [ ] Update documentation
   - [ ] Update tests

   ## API Changes

   [New or modified endpoints, request/response shapes. "None" if N/A]

   ## Data Model Changes

   [Schema changes, new tables/collections, migrations. "None" if N/A]

   ## Infrastructure Changes

   [New services, IaC changes, deployment changes. "None" if N/A]

   ## Acceptance Criteria

   - [ ] [Criterion 1 — testable and specific]
   - [ ] [Criterion 2]

   ## Open Questions

   - [Question 1 — things that need answers before or during implementation]
   ```

5. Review the plan with the user before proceeding to implementation.

6. After the user approves, begin implementation — updating docs as you go.

## Notes

- Plans in `active/` should be moved to `completed/` when done.
- If a plan becomes obsolete, note why and move to `completed/`.
- Reference the plan in commit messages: "Implements [feature-name] plan"
