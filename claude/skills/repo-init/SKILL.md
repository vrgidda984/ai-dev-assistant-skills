---
name: repo-init
description: >
  Initialize a repository with the documentation structure and files expected
  by the shared Claude skills. Analyzes the existing project (package.json,
  README, source code, git history) and populates docs/ templates with
  real project information. Use when setting up a new project, onboarding an
  existing repo to use these skills, or when the user says "initialize",
  "init repo", "set up docs", "bootstrap docs", or "prepare repo for claude skills".
---

# Repository Initialization

Analyze the current repository and generate the `docs/` folder structure
with populated templates so that all shared skills work out of the box.

## Stack Detection Rules

Use these signals to auto-detect which stack packs apply to a project:

| Stack      | Detection Signal                                               |
| ---------- | -------------------------------------------------------------- |
| nestjs     | `package.json` contains `@nestjs/core` in dependencies         |
| python     | `pyproject.toml` exists with `fastapi` in dependencies         |
| nextjs     | `package.json` contains `next` in dependencies                 |
| react      | `package.json` contains `react` in dependencies (without `next`) |
| terraform  | `*.tf` files exist in root or `terraform/` directory           |

If a stack is detected but has no corresponding directory at
`~/.claude/skills/{stack-name}/`, flag it as "detected but not installed".

## When to Use

- Setting up a brand-new project for the first time
- Onboarding an existing repository to use the shared Claude skills
- When `docs/` is missing or incomplete and skills are failing to find expected files

## Steps

### Phase 1 — Discover

Gather context about the project before creating any files.

1. **Read existing files** (skip any that don't exist):
   - `README.md`
   - `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `pom.xml`,
     `build.gradle`, `Gemfile`, `composer.json`, or similar manifest
   - `CLAUDE.md` (project-specific conventions)
   - `docker-compose.yml` / `Dockerfile`
   - `.env.example`
   - `tsconfig.json`, `jest.config.*`, `vitest.config.*`
   - Any `prisma/schema.prisma`, `schema.graphql`, or ORM config

2. **Scan project structure** — run a quick directory listing (`ls` / `find`)
   to understand the layout: source directories, test directories, config files,
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

4a. **Auto-detect stacks** — Using the signals from Phase 1 step 4 and the
    Stack Detection Rules table above, identify which stack packs match the
    project.

4b. **List available stacks** — Scan `~/.claude/skills/` for directories that
    contain a `SKILL.md` file and are known stack packs. Present the user with
    detection results and ask for confirmation:

    ```
    Stack detection results:
      Detected:  [nestjs] (from @nestjs/core in package.json)
      Available: nestjs, python

    Which stacks should be applied to this project?
    Accept detected [nestjs], or specify (comma-separated, or "none"):
    ```

    - If no stacks are detected, still show available stacks and ask.
    - If the user accepts or specifies stacks, record them for Phase 3.
    - If the user says "none", skip stack integration entirely.
    - For monorepos, multiple stacks can be selected (e.g., "nestjs, react").

4c. **Validate selections** — For each selected stack, verify that
    `~/.claude/skills/{stack-name}/SKILL.md` exists. Warn and skip any
    stack that is not installed:

    ```
    WARNING: Stack 'terraform' is not installed at ~/.claude/skills/terraform/.
    Run install.sh and select the 'terraform' stack pack to enable it.
    Skipping terraform.
    ```

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

6. Create each file below **only if it does not already exist**.
   Replace all `[placeholder]` values with real information discovered
   in Phase 1. If a value is unknown, use a sensible default and add a
   `<!-- TODO: fill in -->` comment so the developer can find it later.

#### `docs/architecture/overview.md`

```markdown
# Architecture Overview

_Last updated: [today's date]_

## System Overview

[Fill from README or manifest description — 2-3 sentences about what the project does]

## Tech Stack

| Layer          | Technology     |
| -------------- | -------------- |
| Backend        | [detected framework + language] |
| Frontend       | [detected frontend, or "N/A"] |
| Database       | [detected database, or "N/A"] |
| Infrastructure | [detected infra, or "N/A"] |
| Containerization | [Docker if Dockerfile found, or "N/A"] |

## Module / Service Map

| Module | Purpose | Key Files |
| ------ | ------- | --------- |
| [detected modules from source scan] |

## Data Flow

[Infer from project structure if possible, otherwise leave a TODO]

## Key Design Decisions

See `docs/decisions/` for Architecture Decision Records.
```

#### `docs/architecture/api-contracts.md`

```markdown
# API Contracts

_Last updated: [today's date]_

## Base URL

- Local: `http://localhost:[detected port or 3000]`
- Production: <!-- TODO: fill in -->

## Endpoints

<!-- TODO: document API endpoints -->

## Error Response Format

[Infer from framework defaults if possible]
```

#### `docs/architecture/data-model.md`

```markdown
# Data Model

_Last updated: [today's date]_

## Database

- **Engine**: [detected database]
- **ORM**: [detected ORM]
- **Schema location**: [detected schema file path]

## Entities

[Parse from schema file if available, otherwise leave a TODO]

## Relationships

[Infer from schema if available]

## Migrations

[Infer migration commands from manifest scripts or framework conventions]
```

#### `docs/architecture/infrastructure.md`

```markdown
# Infrastructure

_Last updated: [today's date]_

## Overview

[Fill from docker-compose or infrastructure files]

## Docker Services

[Parse from docker-compose.yml if available]

## Local Development

[Infer start commands from manifest scripts]
```

#### `docs/decisions/_template.md`

Copy this file exactly as-is from the scaffold:

```markdown
# ADR-[NNN]: [Title]

_Date: [YYYY-MM-DD]_
_Status: [Proposed | Accepted | Deprecated | Superseded by ADR-NNN]_

## Context

[What is the issue or decision we need to make? What forces are at play?]

## Options Considered

### Option A: [Name]

- **Description**: [What this approach involves]
- **Pros**: [Benefits]
- **Cons**: [Drawbacks]

### Option B: [Name]

- **Description**: [What this approach involves]
- **Pros**: [Benefits]
- **Cons**: [Drawbacks]

## Decision

[Which option was chosen and WHY. Be specific about the reasoning.]

## Consequences

- [What changes as a result of this decision]
- [What tradeoffs were accepted]
- [What new constraints does this introduce]
- [What becomes easier or harder]
```

#### `docs/sessions/current-state.md`

```markdown
# Current State

_Last updated: [today's date]_

## System Overview

[Same overview from architecture — 2-3 sentences]

## Recent Changes

- Repository initialized for Claude skills workflow

## Current Status

- **Working**: [infer from project state — e.g., "Core application runs locally"]
- **In Progress**: [leave as "N/A" if unknown]
- **Blocked**: [leave as "None" if unknown]

## Next Steps

1. Review and complete TODO items in `docs/` templates
2. [Any next steps inferred from project state]

## Key Context

[Note any discovered gotchas, or "No known issues"]
```

#### `docs/sessions/changelog.md`

```markdown
# Changelog

All notable changes, appended at the top (newest first).

---

## [today's date] — Repository initialized

- **What changed**: Added `docs/` structure for Claude skills workflow
- **Why**: Enable session handoff, feature planning, code review, and documentation workflows
- **Files affected**: `docs/**`
- **Breaking changes**: No
```

#### `docs/plans/active/.gitkeep`

Empty file to ensure the directory is tracked by git.

#### `docs/plans/completed/.gitkeep`

Empty file to ensure the directory is tracked by git.

#### `docs/setup/local-development.md`

```markdown
# Local Development Setup

_Last updated: [today's date]_

## Prerequisites

[Detect from manifest — e.g., Node.js version from engines field, Python version, etc.]

## Quick Start

[Infer from manifest scripts — clone, install, env setup, start commands]

## Running Tests

[Infer test command from manifest scripts]

## Common Tasks

| Task | Command |
| ---- | ------- |
| Start dev server | [detected start/dev command] |
| Run tests | [detected test command] |
| Run linter | [detected lint command] |
| Build | [detected build command] |
```

#### `docs/setup/environment-variables.md`

```markdown
# Environment Variables

_Last updated: [today's date]_

## Overview

- **Local development**: `.env.local` (gitignored)
- **Production**: <!-- TODO: fill in -->
- **Template**: `.env.example` (committed, no real values)

## Variables

[Parse from .env.example if it exists, otherwise leave a TODO]

## Adding New Variables

1. Add to `.env.example` with a placeholder value
2. Add to this document
3. Add to validation schema (if applicable)
4. Update deployment configuration
```

#### `docs/setup/deployment.md`

```markdown
# Deployment

_Last updated: [today's date]_

## Environments

| Environment | URL | Branch | Deploy Method |
| ----------- | --- | ------ | ------------- |
| Development | <!-- TODO --> | `develop` | <!-- TODO --> |
| Production  | <!-- TODO --> | `main` | <!-- TODO --> |

## Deploy Process

<!-- TODO: document deployment steps -->

## Rollback

<!-- TODO: document rollback procedure -->

## Monitoring

<!-- TODO: document monitoring and alerting -->
```

### Phase 3 — CLAUDE.md

7. If `CLAUDE.md` does **not** exist at the project root, create a starter
   file with discovered project conventions:

   ```markdown
   # CLAUDE.md

   ## Project Overview

   [Brief description from README or manifest]

   ## Tech Stack

   [Detected stack summary]

   ## Stack Skills

   This project uses the following stack-specific conventions:

   - **[StackName]**: `~/.claude/skills/[stack-name]/SKILL.md`
     - Testing: `~/.claude/skills/[stack-name]/testing.md`
     - Secrets: `~/.claude/skills/[stack-name]/secrets.md`

   [Repeat for each selected stack from Phase 1.5. Only list files that
   actually exist in the stack directory. If no stacks were selected,
   omit this section entirely.]

   ## Project Structure

   [Key directories and their purpose, discovered from scan]

   ## Development

   - Install: `[detected install command]`
   - Dev server: `[detected dev command]`
   - Test: `[detected test command]`
   - Lint: `[detected lint command]`
   - Build: `[detected build command]`

   ## Conventions

   [Any conventions inferred from existing code — e.g., naming patterns,
   file organization, test patterns. Leave TODOs for unknowns.]
   ```

   If `CLAUDE.md` already exists, check whether it contains a
   `## Stack Skills` section. If it does **not**, append the
   `## Stack Skills` section (shown above) with the confirmed stacks
   from Phase 1.5. If the section already exists, do NOT modify it.

### Phase 4 — Summary

8. Print a summary of everything created:

   ```
   === Repo Initialization Complete ===

   Stack(s) applied: [nestjs]
   (or: No stack packs applied)

   Created:
     docs/architecture/overview.md
     docs/architecture/api-contracts.md
     ...
     CLAUDE.md (with nestjs stack references)

   Skipped (already exist):
     docs/sessions/changelog.md
     ...

   Stack warnings:
     - terraform: not installed (run install.sh to add)
   (or: No stack warnings)

   TODO items remaining: [count]
   Run a find for "<!-- TODO" to see what still needs filling in.

   Your repo is now ready for:
     /handoff    — session handoff
     /plan       — feature planning
     /review     — code review
     /update-docs — documentation sync
     /sync-readme — README sync
   ```

## Important Rules

- **Never overwrite existing files** — skip and report them as "Skipped"
- **Use real data** — don't leave placeholders when the information is discoverable
- **Mark unknowns** — use `<!-- TODO: fill in -->` for values you cannot determine
- **Keep it concise** — don't pad templates with generic filler text
- **Respect .gitignore** — don't create files that should be ignored

## Slash Command Fallback

If this skill doesn't auto-trigger, use: `/init`
