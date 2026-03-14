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

1. **Read existing files** (read fully — skip any that don't exist):
   - `README.md` (read the entire file, do not skim or summarize prematurely)
   - `CONTRIBUTING.md`, `DEVELOPMENT.md`, `GETTING_STARTED.md`
   - `docs/**/*.md` (any existing documentation files — read all of them)
   - `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `pom.xml`,
     `build.gradle`, `Gemfile`, `composer.json`, or similar manifest
   - `CLAUDE.md` (project-specific conventions)
   - `docker-compose.yml` / `Dockerfile`
   - `.env.example`
   - `tsconfig.json`, `jest.config.*`, `vitest.config.*`
   - Any `prisma/schema.prisma`, `schema.graphql`, or ORM config
   - `openapi.yaml`, `swagger.json`, or API specification files

1b. **Catalog existing documentation depth** — For each existing doc file read,
    note the level of detail it contains (brief / moderate / comprehensive).
    This determines how much content needs to be extracted into generated docs.
    If existing docs are comprehensive, the generated docs must match that depth.

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

### Phase 2 — Deep Code Analysis

Go beyond config files and documentation — analyze the actual source code to
build an accurate inventory of what the project really does. This ensures the
generated docs reflect the code, not stale documentation.

**Performance guardrails:**
- Use grep/glob to locate files first, then read only relevant matches.
- If more than 50 files match a pattern, sample the first 30 by modification date
  and note that a sample was used.
- Skip `node_modules/`, `dist/`, `build/`, `.next/`, `__pycache__/`, `venv/`,
  and other build/dependency directories.
- Read only relevant sections (route definitions, model classes, decorator blocks),
  not full service implementations.

5. **Scan source code for API endpoints** — Use the detected stack to target the
   right file patterns and decorators/functions:

   | Stack | Glob Pattern | Search Patterns |
   | ----- | ------------ | --------------- |
   | NestJS | `src/**/*.controller.ts` | `@Get`, `@Post`, `@Put`, `@Patch`, `@Delete`, `@Controller('...')` |
   | FastAPI | `**/routers/*.py`, `**/routes/*.py`, `app/**/*.py` | `@router.get`, `@router.post`, `@app.get`, `APIRouter(prefix=...)` |
   | Next.js | `app/**/route.ts`, `pages/api/**/*.ts` | `export async function GET/POST`, `export default function handler` |
   | Express | `src/**/*route*.ts`, `src/**/*router*.ts` | `router.get(`, `router.post(`, `app.get(` |
   | Generic | Files matching `*route*`, `*controller*`, `*endpoint*` | HTTP method patterns |

   Build an **Endpoints Inventory**: method, path, handler function, file:line.

6. **Scan source code for data models/entities** — Locate model definitions using
   stack-specific patterns:

   | Stack | Glob Pattern | Search Patterns |
   | ----- | ------------ | --------------- |
   | Prisma | `prisma/schema.prisma` | `model <Name> {` blocks |
   | TypeORM | `src/**/*.entity.ts` | `@Entity()`, `@Column()`, `@PrimaryGeneratedColumn()` |
   | SQLAlchemy | `**/models/*.py`, `app/models/*.py` | Classes inheriting `Base`, `mapped_column`, `__tablename__` |
   | Django | `**/models.py` | `models.Model` subclasses |
   | Generic | `migrations/`, `alembic/versions/` | `CREATE TABLE`, `ALTER TABLE` |

   Build a **Models Inventory**: entity name, fields with types, file location,
   relationships.

7. **Scan source code for environment variable usage** — Grep across all source
   files (excluding dependency/build directories):

   | Stack | Search Patterns |
   | ----- | --------------- |
   | Node.js / TypeScript | `process.env.`, `ConfigService.get(`, `@Env()` |
   | Python | `os.environ`, `os.getenv`, `settings.`, `Field(env=` |
   | Generic | `getenv`, `ENV[`, config access patterns |

   Build an **Env Vars Inventory**: variable name, where used (file:line),
   whether it appears in `.env.example`, whether it has a default value.

8. **Scan for test coverage and CI/CD** —

   - Identify test files per module/service and count test cases:
     - Node.js: `**/*.spec.ts`, `**/*.test.ts`, `test/**/*.e2e-spec.ts`
     - Python: `tests/**/*.py`, `**/test_*.py`
   - Scan for CI/CD pipeline configs: `.github/workflows/*.yml`, `Jenkinsfile`,
     `.gitlab-ci.yml`, `.circleci/config.yml`, `bitbucket-pipelines.yml`
   - Note what the pipelines do (lint, test, build, deploy targets)

9. **Check actual dependency usage** — Compare manifest dependencies against
   actual import statements found in source code. Flag dependencies that appear
   in the manifest but are never imported (potentially unused).

### Phase 2.5 — Validation Report & Approval

Before generating any documentation, present the user with a structured comparison
of what the code actually does versus what existing documentation claims. The user
must approve before proceeding.

10. **Build discrepancy matrix** — Compare the inventories from Phase 2 (code)
    against the documentation cataloged in Phase 1 (existing docs). Classify
    each item as:

    - **MATCH** — code and docs agree
    - **MISMATCH** — both mention it but details differ (e.g., different path, missing fields)
    - **UNDOCUMENTED** — exists in code but not in any existing docs
    - **STALE** — mentioned in docs but not found in code (possibly removed)

11. **Present the validation report** — Display the following report to the user:

    ```
    === Code Analysis & Documentation Validation Report ===

    ## 1. API Endpoints

    Code defines [N] endpoints:
      POST   /users           (src/users/users.controller.ts:24)
      GET    /users           (src/users/users.controller.ts:31)
      ...

    Existing docs mention [M] endpoints:
      POST   /users           -- MATCH
      GET    /api/users/:id   -- MISMATCH: code uses /users/:id (no /api prefix)
      POST   /auth/register   -- STALE: not found in code

    Undocumented (in code, not in docs):
      POST   /auth/login

    ## 2. Data Models
    [Same pattern: code entities vs documented entities, field-level diffs]

    ## 3. Environment Variables
    [Code usage vs .env.example vs docs — flag undocumented and stale vars]

    ## 4. Dependencies
    [Manifest vs actual imports — flag potentially unused]

    ## 5. Test Coverage
    [Modules with/without tests, CI/CD pipelines found]

    ## Summary

    | Category  | In Code | In Docs | Match | Mismatch | Undocumented | Stale |
    | --------- | ------- | ------- | ----- | -------- | ------------ | ----- |
    | Endpoints | 4       | 4       | 2     | 1        | 1            | 1     |
    | Models    | 2       | 2       | 1     | 0        | 1            | 1     |
    | Env Vars  | 4       | 3       | 2     | 0        | 2            | 1     |

    Generated docs will use CODE as the source of truth.
    Proceed with documentation generation? [Y/n, or provide corrections]
    ```

    **Edge cases for the report:**
    - **No existing docs**: Phase 2 still runs for accurate data. Report says
      "No existing documentation found to validate against. Generated docs will
      be based entirely on code analysis." Still requires user approval.
    - **No source code found**: Skip Phase 2 entirely with note "No source code
      found to analyze. Generated docs will be based on existing documentation
      and config files only."
    - **Monorepo**: Run scans per stack in respective directories, present a
      combined report.
    - **OpenAPI/Swagger spec exists**: Use as an additional cross-reference
      source, but code remains the ultimate source of truth.

12. **Wait for user approval** — Do **not** proceed to Phase 3 until the user
    has reviewed and explicitly approved the report. The user can:

    - **Approve** ("Y", "yes", "proceed") — continue to scaffold
    - **Abort** ("N", "no") — stop entirely
    - **Provide corrections** — free-text input, e.g., "Bull is used in a cron
      job not scanned, keep it" or "The /api prefix is intentional, our reverse
      proxy adds it." Incorporate corrections into the inventories before
      proceeding. Do not re-present the full report unless corrections are
      substantial enough to change multiple categories.

### Documentation Extraction Policy

When existing documentation is found (README.md, wiki pages, existing `docs/` files,
inline code comments, manifest descriptions), follow these rules:

1. **Extract and incorporate** — Pull ALL substantive details from existing docs
   into the generated `docs/` files. The generated docs must be self-contained;
   a reader should never need to consult the original source to understand the system.

2. **Do not defer** — Never write phrases like "See README for details",
   "Refer to existing documentation", or "See [file] for more information"
   as the primary content. The generated doc IS the primary content.

3. **Reference as supplementary** — At the bottom of any generated doc that drew
   from existing sources, add a `## Related Resources` section listing the
   original files (now in `old_docs_not_relevant/`) for historical reference.

4. **Synthesize, don't copy** — Reorganize extracted information to fit the
   template structure. Merge overlapping content. Resolve contradictions
   by favoring the most recent source (git log dates, file modification times).

5. **Match existing depth** — When existing documentation provides detail, match
   or exceed that level of detail in the generated docs. If the README has a
   thorough architecture section, the generated `docs/architecture/overview.md`
   must contain all of that information and more.

6. **Code is the source of truth** — When Phase 2 analysis reveals discrepancies
   between what the code does and what existing documentation claims, always
   favor the code. Document what the code actually does. Note significant
   discrepancies with a `<!-- NOTE: Existing docs said X, but code analysis
   found Y -->` comment for transparency.

### Phase 3 — Scaffold

Create the docs directory structure and comprehensive documentation using the
validated inventories from Phase 2 and user-approved corrections from Phase 2.5.

13. **Move pre-existing documentation** — Before creating any files, scan the
    entire repo for existing documentation files (`.md`) that were **not**
    generated by a previous run of this skill. Move them to `old_docs_not_relevant/`
    with an `OLD_` prefix so the skill-generated docs become the canonical
    source of truth.

    **Scope — move these from anywhere in the repo:**
    - `README.md`, `CONTRIBUTING.md`, `DEVELOPMENT.md`, `GETTING_STARTED.md`
    - Any `.md` files under `docs/` that don't match skill-generated filenames
    - Any other documentation `.md` files at root or in subdirectories
      (e.g., `wiki/`, `guides/`)

    **Do NOT move:**
    - `CLAUDE.md` / `.github/copilot-instructions.md` (tool config)
    - `.gitkeep` files
    - Files inside `node_modules/`, `.git/`, or other dependency/build directories
    - `docs/decisions/_template.md` (ADR template)
    - License files (`LICENSE`, `LICENSE.md`)
    - Files already prefixed with `OLD_`

    **Process:**
    1. Create `old_docs_not_relevant/` directory at the repo root
    2. For each pre-existing doc, rename with `OLD_` prefix and move to
       `old_docs_not_relevant/`, preserving relative path structure:
       - `README.md` → `old_docs_not_relevant/OLD_README.md`
       - `docs/api-guide.md` → `old_docs_not_relevant/docs/OLD_api-guide.md`
       - `guides/setup.md` → `old_docs_not_relevant/guides/OLD_setup.md`
    3. Previously skill-generated docs under `docs/` (from a prior init run)
       are **overwritten** in place with new comprehensive versions (not moved)

    **How to identify skill-generated docs:**
    The 11 files created in step 15 below (e.g., `docs/architecture/overview.md`,
    `docs/setup/local-development.md`, etc.). If these already exist from a
    prior skill run, overwrite them — do not move them.

14. Create the following directories (skip any that already exist):

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

15. Create each file below (overwrite if it exists from a prior skill run).
   Replace all `[placeholder]` values with real information discovered
   in Phase 1 and validated in Phase 2. Use the Phase 2 inventories
   (endpoints, models, env vars) as the primary data source. Follow
   the Documentation Extraction Policy — incorporate ALL details from
   code analysis, existing docs, and config files. If a value is truly
   unknown, use a sensible default and add a `<!-- TODO: fill in -->`
   comment so the developer can find it later.

#### `docs/architecture/overview.md`

```markdown
# Architecture Overview

_Last updated: [today's date]_

## System Overview

[Extract the full project description from README.md, manifest files, and any existing
documentation. Include: what the project does, who uses it, what problems it solves,
and its key capabilities. Write as many sentences as needed to fully describe the
system — do not truncate information that exists in the source material.]

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
| [List EVERY module/service discovered from the source scan AND from existing
documentation. For each module include: name, a 1-2 sentence purpose description,
and the key file paths. If the README or existing docs describe modules, extract
ALL of that information here.] |

## Data Flow

[Describe the primary request/data flow through the system. Extract from README,
architecture docs, or infer from source code. Include: entry points, middleware/
processing layers, data stores, and external service integrations. If the README
or existing docs describe architecture or data flow, incorporate all detail here.
Only leave a TODO if truly undiscoverable.]

## Key Design Decisions

See `docs/decisions/` for Architecture Decision Records.

## Related Resources

[List any existing documentation files (now in old_docs_not_relevant/) that provided
source material for this doc. Omit this section if no existing docs were found.]
```

#### `docs/architecture/api-contracts.md`

```markdown
# API Contracts

_Last updated: [today's date]_

## Base URL

- Local: `http://localhost:[detected port or 3000]`
- Production: <!-- TODO: fill in -->

## Endpoints

[Use the validated Endpoints Inventory from Phase 2 as the primary source.
Cross-reference with existing documentation and Swagger/OpenAPI specs.
For each endpoint document: method, path, description, auth requirements,
request body shape, and response shape. Do not leave this as a TODO if
endpoint information was discovered during code analysis.]

## Error Response Format

[Infer from framework defaults if possible. Extract from existing docs if documented.]

## Related Resources

[List any existing documentation files that provided source material for this doc.]
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

[Use the validated Models Inventory from Phase 2 as the primary source.
Cross-reference with schema files and existing documentation. For each entity
list ALL columns with types, constraints, and descriptions. Do not leave as
a TODO if model information was discovered during code analysis.]

## Relationships

[Document ALL entity relationships extracted from schema files and existing docs.
Include: relationship type (1:1, 1:N, M:N), foreign keys, and join tables.]

## Migrations

[Infer migration commands from manifest scripts or framework conventions. Include
the full workflow: creating, running, and reverting migrations.]

## Related Resources

[List any existing documentation files that provided source material for this doc.]
```

#### `docs/architecture/infrastructure.md`

```markdown
# Infrastructure

_Last updated: [today's date]_

## Overview

[Extract full infrastructure description from docker-compose, Dockerfiles, IaC files,
CI/CD configs, and existing documentation. Include: hosting platform, cloud services,
networking topology, and deployment architecture.]

## Docker Services

[Parse ALL services from docker-compose.yml if available. For each service list:
name, image, ports, volumes, environment variables, and dependencies. Extract
additional detail from existing docs.]

## Local Development

[Infer start commands from manifest scripts. Include the full local development
workflow: starting services, seeding databases, running in watch mode, etc.]

## Related Resources

[List any existing documentation files that provided source material for this doc.]
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

[Full system overview matching the depth of architecture/overview.md — include all
key details about what the system does, its current capabilities, and maturity level.]

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

[List ALL prerequisites extracted from: manifest engine fields, README setup sections,
Dockerfile base images, .tool-versions, .nvmrc, and existing setup docs. Include
specific version requirements, system dependencies, and any tools that must be
pre-installed. If the README has detailed setup instructions, incorporate ALL of
that information here.]

## Quick Start

[Provide complete step-by-step setup instructions extracted from: README,
CONTRIBUTING.md, existing setup docs, manifest scripts, and docker-compose files.
Include every step a new developer needs: cloning, dependency installation,
environment setup, database setup, seed data, and starting the application.
If the README has a detailed quick-start guide, incorporate all steps here.]

## Running Tests

[Extract full testing instructions from manifest scripts, README, and existing docs.
Include: unit tests, integration tests, e2e tests, and any test-specific setup.]

## Common Tasks

| Task | Command |
| ---- | ------- |
| Start dev server | [detected start/dev command] |
| Run tests | [detected test command] |
| Run linter | [detected lint command] |
| Build | [detected build command] |

## Related Resources

[List any existing documentation files that provided source material for this doc.]
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

[Use the validated Env Vars Inventory from Phase 2 as the primary source.
Cross-reference with .env.example and existing documentation. For each
variable list: name, description, example value, where it's used in code,
and whether it's required. Do not leave as a TODO if env var usage was
discovered during code analysis.]

## Adding New Variables

1. Add to `.env.example` with a placeholder value
2. Add to this document
3. Add to validation schema (if applicable)
4. Update deployment configuration

## Related Resources

[List any existing documentation files that provided source material for this doc.]
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

## Related Resources

[List any existing documentation files that provided source material for this doc.]
```

### Phase 4 — CLAUDE.md

16. If `CLAUDE.md` does **not** exist at the project root, create a starter
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

### Phase 5 — Summary

17. Print a summary of everything created:

   ```
   === Repo Initialization Complete ===

   Stack(s) applied: [nestjs]
   (or: No stack packs applied)

   Moved to old_docs_not_relevant/:
     README.md → old_docs_not_relevant/OLD_README.md
     CONTRIBUTING.md → old_docs_not_relevant/OLD_CONTRIBUTING.md
     docs/api-guide.md → old_docs_not_relevant/docs/OLD_api-guide.md
     ...
   (or: No pre-existing docs found to move)

   Created (or overwritten):
     docs/architecture/overview.md
     docs/architecture/api-contracts.md
     ...
     CLAUDE.md (with nestjs stack references)

   Stack warnings:
     - terraform: not installed (run install.sh to add)
   (or: No stack warnings)

   Code analysis: [N] endpoints, [M] models, [P] env vars discovered
   Discrepancies resolved: [count] (code used as source of truth)
   User corrections applied: [count]
   (or: No existing docs to validate against)

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

- **Move pre-existing docs, overwrite prior skill output** — Pre-existing non-skill
  docs get `OLD_` prefix and are moved to `old_docs_not_relevant/`. Previously
  skill-generated docs under `docs/` are overwritten with new comprehensive versions.
- **Use real data** — don't leave placeholders when the information is discoverable
- **Mark unknowns** — use `<!-- TODO: fill in -->` for values you cannot determine
- **Be comprehensive, not padded** — include ALL substantive details extracted from
  existing documentation and source code. Do not truncate or summarize information
  that exists. However, do not add generic filler text that says nothing specific
  about the project. Every sentence should carry project-specific information.
- **Generated docs are canonical** — the `docs/` files you create are the primary
  reference. Existing docs (now in `old_docs_not_relevant/`) become supplementary.
  Never defer to them as "see X for details."
- **Respect .gitignore** — don't create files that should be ignored

## Slash Command Fallback

If this skill doesn't auto-trigger, use: `/init`
