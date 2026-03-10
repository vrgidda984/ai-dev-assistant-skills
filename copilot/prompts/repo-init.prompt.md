---
mode: "agent"
description: "Initialize a repo with docs structure and Copilot configuration"
---

# Repository Initialization

Analyze the current repository and generate the `docs/` folder structure
with populated templates so that all shared prompts work out of the box.

## Stack Detection Rules

Use these signals to auto-detect which stack packs apply to a project:

| Stack      | Detection Signal                                               |
| ---------- | -------------------------------------------------------------- |
| nestjs     | `package.json` contains `@nestjs/core` in dependencies         |
| python     | `pyproject.toml` exists with `fastapi` in dependencies         |
| nextjs     | `package.json` contains `next` in dependencies                 |
| react      | `package.json` contains `react` in dependencies (without `next`) |
| terraform  | `*.tf` files exist in root or `terraform/` directory           |

If a stack is detected but has no corresponding instruction file in
`.github/instructions/`, flag it as "detected but not installed".

## When to Use

- Setting up a brand-new project for the first time
- Onboarding an existing repository to use the shared Copilot skills
- When `docs/` is missing or incomplete and prompts are failing to find expected files

## Steps

### Phase 1 — Discover

Gather context about the project before creating any files.

1. **Read existing files** (skip any that don't exist):
   - `README.md`
   - `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `pom.xml`,
     `build.gradle`, `Gemfile`, `composer.json`, or similar manifest
   - `.github/copilot-instructions.md` (project-specific conventions)
   - `docker-compose.yml` / `Dockerfile`
   - `.env.example`
   - `tsconfig.json`, `jest.config.*`, `vitest.config.*`
   - Any `prisma/schema.prisma`, `schema.graphql`, or ORM config

2. **Scan project structure** — run a quick directory listing to understand
   the layout: source directories, test directories, config files,
   infrastructure files (terraform/, cdk/, etc.).

3. **Check git log** (last ~20 commits) to understand recent activity and
   project maturity.

4. **Identify the stack** — determine:
   - Language(s) and runtime (Node, Python, Go, Rust, Java, etc.)
   - Framework(s) (NestJS, Next.js, FastAPI, Rails, etc.)
   - Database (PostgreSQL, MySQL, MongoDB, SQLite, etc.)
   - ORM / query builder (Prisma, TypeORM, SQLAlchemy, etc.)
   - Infrastructure (Docker, AWS, GCP, Vercel, etc.)
   - Test framework (Jest, Vitest, Pytest, etc.)
   - Linter / formatter (ESLint, Prettier, Ruff, etc.)

### Phase 1.5 — Stack Selection

4a. **Auto-detect stacks** — Using the signals from Phase 1 and the
    Stack Detection Rules table above, identify which stack packs match.

4b. **Present detection results** and ask the user for confirmation:

    ```
    Stack detection results:
      Detected:  [nestjs] (from @nestjs/core in package.json)
      Available: nestjs, python

    Which stacks should be applied to this project?
    Accept detected [nestjs], or specify (comma-separated, or "none"):
    ```

4c. **Validate selections** — For each selected stack, verify that
    `.github/instructions/{stack-name}.instructions.md` exists.

### Phase 2 — Scaffold

Create the docs directory structure. **Never overwrite files that already exist.**

5. Create the following directories (skip any that already exist):

   ```
   docs/
   ├── architecture/
   ├── decisions/
   ├── sessions/
   ├── plans/
   │   ├── active/
   │   └── completed/
   └── setup/
   ```

6. Create each documentation file **only if it does not already exist**.
   Replace all `[placeholder]` values with real information discovered
   in Phase 1. If a value is unknown, use a sensible default and add a
   `<!-- TODO: fill in -->` comment.

   Files to create:
   - `docs/architecture/overview.md` — System overview, tech stack, module map
   - `docs/architecture/api-contracts.md` — API endpoints, base URL, error format
   - `docs/architecture/data-model.md` — Database, entities, relationships
   - `docs/architecture/infrastructure.md` — Docker services, deployment topology
   - `docs/decisions/_template.md` — ADR template
   - `docs/sessions/current-state.md` — Initial project state snapshot
   - `docs/sessions/changelog.md` — Initial changelog entry
   - `docs/plans/active/.gitkeep` — Empty file for git tracking
   - `docs/plans/completed/.gitkeep` — Empty file for git tracking
   - `docs/setup/local-development.md` — Prerequisites, quick start, common tasks
   - `docs/setup/environment-variables.md` — Env var reference
   - `docs/setup/deployment.md` — Deployment process

### Phase 3 — Summary

7. Print a summary of everything created:

   ```
   === Repo Initialization Complete ===

   Stack(s) applied: [nestjs]

   Created:
     docs/architecture/overview.md
     docs/architecture/api-contracts.md
     ...

   Skipped (already exist):
     docs/sessions/changelog.md
     ...

   TODO items remaining: [count]
   Run a find for "<!-- TODO" to see what still needs filling in.

   Your repo is now ready for these prompts:
     session-handoff  — end-of-session documentation
     resume-session   — start-of-session context loading
     plan-feature     — feature planning
     code-review      — code quality review
     update-docs      — documentation sync
     sync-readme      — README sync
   ```

## Important Rules

- **Never overwrite existing files** — skip and report them as "Skipped"
- **Use real data** — don't leave placeholders when the information is discoverable
- **Mark unknowns** — use `<!-- TODO: fill in -->` for values you cannot determine
- **Keep it concise** — don't pad templates with generic filler text
- **Respect .gitignore** — don't create files that should be ignored
