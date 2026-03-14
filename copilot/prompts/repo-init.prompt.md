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

1. **Read existing files** (read fully — skip any that don't exist):
   - `README.md` (read the entire file, do not skim or summarize prematurely)
   - `CONTRIBUTING.md`, `DEVELOPMENT.md`, `GETTING_STARTED.md`
   - `docs/**/*.md` (any existing documentation files — read all of them)
   - `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `pom.xml`,
     `build.gradle`, `Gemfile`, `composer.json`, or similar manifest
   - `.github/copilot-instructions.md` (project-specific conventions)
   - `docker-compose.yml` / `Dockerfile`
   - `.env.example`
   - `tsconfig.json`, `jest.config.*`, `vitest.config.*`
   - Any `prisma/schema.prisma`, `schema.graphql`, or ORM config
   - `openapi.yaml`, `swagger.json`, or API specification files

1b. **Catalog existing documentation depth** — For each existing doc file read,
    note the level of detail it contains (brief / moderate / comprehensive).
    This determines how much content needs to be extracted into generated docs.
    If existing docs are comprehensive, the generated docs must match that depth.

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
    - `.github/copilot-instructions.md` (tool config)
    - `CLAUDE.md` (tool config)
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
    The 11 files listed in step 15 below. If these already exist from a prior
    skill run, overwrite them — do not move them.

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

15. Create each documentation file (overwrite if it exists from a prior skill run).
   Replace all `[placeholder]` values with real information discovered in Phase 1
   and validated in Phase 2. Use the Phase 2 inventories (endpoints, models,
   env vars) as the primary data source. Follow the Documentation Extraction
   Policy — incorporate ALL details from code analysis, existing docs, and
   config files. If a value is truly unknown, use a sensible default and add
   a `<!-- TODO: fill in -->` comment. Add a `## Related Resources` section
   at the bottom of each generated doc that drew from existing sources.

   Files to create:
   - `docs/architecture/overview.md` — Comprehensive system overview, tech stack, full module map, data flow
   - `docs/architecture/api-contracts.md` — ALL API endpoints from Phase 2 Endpoints Inventory, cross-referenced with docs, error format
   - `docs/architecture/data-model.md` — ALL entities, columns, relationships from Phase 2 Models Inventory, cross-referenced with schema and docs
   - `docs/architecture/infrastructure.md` — Full infrastructure details from docker-compose, IaC, docs
   - `docs/decisions/_template.md` — ADR template
   - `docs/sessions/current-state.md` — Comprehensive project state snapshot
   - `docs/sessions/changelog.md` — Initial changelog entry
   - `docs/plans/active/.gitkeep` — Empty file for git tracking
   - `docs/plans/completed/.gitkeep` — Empty file for git tracking
   - `docs/setup/local-development.md` — Complete prerequisites, full step-by-step setup, all common tasks
   - `docs/setup/environment-variables.md` — ALL env vars from Phase 2 Env Vars Inventory, cross-referenced with .env.example and docs
   - `docs/setup/deployment.md` — Full deployment process from existing docs and CI/CD configs

### Phase 4 — Summary

16. Print a summary of everything created:

   ```
   === Repo Initialization Complete ===

   Stack(s) applied: [nestjs]

   Moved to old_docs_not_relevant/:
     README.md → old_docs_not_relevant/OLD_README.md
     CONTRIBUTING.md → old_docs_not_relevant/OLD_CONTRIBUTING.md
     ...
   (or: No pre-existing docs found to move)

   Created (or overwritten):
     docs/architecture/overview.md
     docs/architecture/api-contracts.md
     ...

   Code analysis: [N] endpoints, [M] models, [P] env vars discovered
   Discrepancies resolved: [count] (code used as source of truth)
   User corrections applied: [count]
   (or: No existing docs to validate against)

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
